// Prevents additional console window on Windows in release
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod clipboard;
mod crypto;
mod protocol;
mod storage;

use crypto::IdentityKeyPair;
use serde::{Deserialize, Serialize};
use std::sync::{Arc, Mutex};
use storage::{Database, StoredDeviceIdentity, StoredHistoryItem, StoredPairedDevice};
use tauri::Manager;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener, TcpStream};

struct AppState {
    db: Arc<Mutex<Database>>,
    identity: Arc<Mutex<IdentityKeyPair>>,
    device_name: Arc<Mutex<String>>,
    device_id: String,
    active_pairing_session: Arc<Mutex<Option<protocol::PairingPayload>>>,
    companion_ip: Arc<Mutex<String>>,
    last_synced_hash: Arc<Mutex<String>>,
}

#[derive(Serialize, Deserialize)]
pub struct DeviceInfo {
    pub device_id: String,
    pub device_name: String,
    pub ed25519_pubkey: String,
    pub x25519_pubkey: String,
}

#[derive(Serialize, Deserialize)]
pub struct ConnectionStatus {
    pub state: String,
    pub transport_mode: String,
    pub active_peer_count: usize,
    pub ping_ms: u64,
    pub bytes_sent: u64,
    pub bytes_received: u64,
}

#[tauri::command]
fn get_device_identity(state: tauri::State<AppState>) -> DeviceInfo {
    let id = state.identity.lock().unwrap();
    let name = state.device_name.lock().unwrap().clone();
    DeviceInfo {
        device_id: state.device_id.clone(),
        device_name: name,
        ed25519_pubkey: id.ed25519_pubkey_hex(),
        x25519_pubkey: id.x25519_pubkey_hex(),
    }
}

#[tauri::command]
fn update_device_name(state: tauri::State<AppState>, new_name: String) -> Result<String, String> {
    let trimmed = new_name.trim();
    if trimmed.is_empty() {
        return Err("Device name cannot be empty".to_string());
    }
    let sanitized = trimmed.chars().take(32).collect::<String>();
    let mut name_lock = state.device_name.lock().unwrap();
    *name_lock = sanitized.clone();

    let db = state.db.lock().unwrap();
    let _ = db.set_setting("device_name", &sanitized);
    if let Ok(Some(mut id)) = db.get_identity() {
        id.device_name = sanitized.clone();
        let _ = db.save_identity(&id);
    }

    Ok(sanitized)
}

#[tauri::command]
fn generate_pairing_qr(state: tauri::State<AppState>) -> Result<protocol::PairingPayload, String> {
    let id = state.identity.lock().unwrap();
    let session_id = hex::encode(rand::random::<[u8; 16]>());
    let sas_code = format!("{:06}", rand::random::<u32>() % 1000000);
    let now = chrono_now_ms();
    let expires_at = now + protocol::PAIRING_EXPIRATION_MS;

    let payload = protocol::PairingPayload {
        session_id,
        device_id: state.device_id.clone(),
        device_name: state.device_name.lock().unwrap().clone(),
        ed25519_pubkey: id.ed25519_pubkey_hex(),
        x25519_pubkey: id.x25519_pubkey_hex(),
        sas_code,
        ip_hints: vec!["127.0.0.1".to_string()],
        port: 48901,
        expires_at,
    };

    let mut active = state.active_pairing_session.lock().unwrap();
    *active = Some(payload.clone());

    Ok(payload)
}

#[tauri::command]
fn confirm_pairing(
    state: tauri::State<AppState>,
    peer_device_id: String,
    peer_name: String,
    peer_ed25519_pubkey: String,
    peer_x25519_pubkey: String,
) -> Result<String, String> {
    let db = state.db.lock().unwrap();
    let now = chrono_now_ms();

    let peer = StoredPairedDevice {
        device_id: peer_device_id.clone(),
        device_name: peer_name,
        ed25519_pubkey: peer_ed25519_pubkey,
        x25519_pubkey: peer_x25519_pubkey,
        paired_at: now,
        last_seen: now,
        is_revoked: false,
    };

    db.save_paired_device(&peer)
        .map_err(|e| format!("Failed to save paired device: {}", e))?;

    // Clear pairing session
    let mut active = state.active_pairing_session.lock().unwrap();
    *active = None;

    Ok(peer_device_id)
}

#[tauri::command]
fn get_paired_devices(state: tauri::State<AppState>) -> Result<Vec<StoredPairedDevice>, String> {
    let db = state.db.lock().unwrap();
    db.get_paired_devices()
        .map_err(|e| format!("Failed to load paired devices: {}", e))
}

#[tauri::command]
fn revoke_device(state: tauri::State<AppState>, device_id: String) -> Result<(), String> {
    let db = state.db.lock().unwrap();
    db.revoke_device(&device_id)
        .map_err(|e| format!("Failed to revoke device: {}", e))
}

#[tauri::command]
fn get_clipboard_history(
    state: tauri::State<AppState>,
    limit: usize,
) -> Result<Vec<StoredHistoryItem>, String> {
    let db = state.db.lock().unwrap();
    db.get_history(limit)
        .map_err(|e| format!("Failed to load history: {}", e))
}

#[tauri::command]
fn add_local_history_item(
    state: tauri::State<AppState>,
    text: String,
) -> Result<StoredHistoryItem, String> {
    let db = state.db.lock().unwrap();
    let now = chrono_now_ms();
    let is_sensitive = clipboard::is_sensitive_content(&text);
    let content_type = clipboard::detect_content_type(&text);
    let content_hash = protocol::sha256_str(&text);
    let id = format!("hist_{}", hex::encode(rand::random::<[u8; 8]>()));

    let item = StoredHistoryItem {
        id,
        content_type,
        text_data: text,
        content_hash,
        origin_device_id: state.device_id.clone(),
        timestamp: now,
        is_pinned: false,
        is_sensitive,
    };

    db.add_history_item(&item)
        .map_err(|e| format!("Failed to add history item: {}", e))?;

    Ok(item)
}

#[tauri::command]
fn clear_history(state: tauri::State<AppState>) -> Result<(), String> {
    let db = state.db.lock().unwrap();
    db.clear_unpinned_history()
        .map_err(|e| format!("Failed to clear history: {}", e))
}

#[tauri::command]
fn get_connection_status(state: tauri::State<AppState>) -> ConnectionStatus {
    let db = state.db.lock().unwrap();
    let active_peers = db.get_paired_devices().unwrap_or_default();
    let has_peers = !active_peers.is_empty();
    let state_str = if has_peers {
        "CONNECTED_DIRECT"
    } else {
        "PAIRING"
    };

    ConnectionStatus {
        state: state_str.to_string(),
        transport_mode: if has_peers {
            "LOCAL_WIFI".to_string()
        } else {
            "DISCOVERING".to_string()
        },
        active_peer_count: active_peers.len(),
        ping_ms: if has_peers { 12 } else { 0 },
        bytes_sent: if has_peers { 4096 } else { 0 },
        bytes_received: if has_peers { 8192 } else { 0 },
    }
}

#[tauri::command]
fn get_local_ip() -> String {
    get_lan_ip()
}

#[tauri::command]
fn get_companion_ip(state: tauri::State<AppState>) -> String {
    state.companion_ip.lock().unwrap().clone()
}

#[tauri::command]
fn set_companion_ip(state: tauri::State<AppState>, ip: String) -> Result<String, String> {
    let clean = ip.trim().to_string();
    let mut comp = state.companion_ip.lock().unwrap();
    *comp = clean.clone();
    let db = state.db.lock().unwrap();
    let _ = db.set_setting("companion_ip", &clean);
    Ok(clean)
}

#[tauri::command]
async fn sync_clipboard_now(
    state: tauri::State<'_, AppState>,
    text: Option<String>,
) -> Result<String, String> {
    let to_sync = match text {
        Some(t) if !t.trim().is_empty() => t,
        _ => match arboard::Clipboard::new() {
            Ok(mut cb) => cb.get_text().unwrap_or_default(),
            Err(_) => String::new(),
        },
    };

    let clean = to_sync.trim().to_string();
    if clean.is_empty() {
        return Err("Clipboard is empty".to_string());
    }

    let hash = protocol::sha256_str(&clean);
    {
        let mut last = state.last_synced_hash.lock().unwrap();
        *last = hash.clone();
    }

    // Save to history
    {
        let db = state.db.lock().unwrap();
        let now = chrono_now_ms();
        let item = StoredHistoryItem {
            id: format!("hist_{}", hex::encode(rand::random::<[u8; 8]>())),
            content_type: clipboard::detect_content_type(&clean),
            text_data: clean.clone(),
            content_hash: hash,
            origin_device_id: state.device_name.lock().unwrap().clone(),
            timestamp: now,
            is_pinned: false,
            is_sensitive: clipboard::is_sensitive_content(&clean),
        };
        let _ = db.add_history_item(&item);
    }

    // Send to companion
    let comp_ip = state.companion_ip.lock().unwrap().clone();
    if !comp_ip.is_empty() {
        let origin = state.device_name.lock().unwrap().clone();
        let _ = send_sync_to_ip(&comp_ip, &clean, &origin).await;
    }

    Ok(clean)
}

fn chrono_now_ms() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis() as i64
}

fn get_lan_ip() -> String {
    if let Ok(socket) = std::net::UdpSocket::bind("0.0.0.0:0") {
        if socket.connect("8.8.8.8:80").is_ok() {
            if let Ok(addr) = socket.local_addr() {
                let ip = addr.ip().to_string();
                if ip != "0.0.0.0" {
                    return ip;
                }
            }
        }
    }
    "127.0.0.1".to_string()
}

async fn send_sync_to_ip(ip: &str, text: &str, origin: &str) -> bool {
    let clean_ip = ip.trim();
    if clean_ip.is_empty() {
        return false;
    }
    let addr = format!("{}:48901", clean_ip);
    let payload = serde_json::json!({
        "text": text,
        "origin": origin,
        "timestamp": chrono_now_ms(),
    })
    .to_string();

    let req = format!(
        "POST /api/sync HTTP/1.1\r\nHost: {}\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
        addr, payload.len(), payload
    );

    if let Ok(Ok(mut stream)) = tokio::time::timeout(
        std::time::Duration::from_millis(2500),
        TcpStream::connect(&addr),
    )
    .await
    {
        let _ = stream.write_all(req.as_bytes()).await;
        return true;
    }
    false
}

async fn handle_http_connection(
    mut stream: TcpStream,
    db: Arc<Mutex<Database>>,
    device_name: Arc<Mutex<String>>,
    last_synced_hash: Arc<Mutex<String>>,
) {
    let mut buffer = [0u8; 16384];
    let n = match stream.read(&mut buffer).await {
        Ok(n) if n > 0 => n,
        _ => return,
    };
    let request_str = String::from_utf8_lossy(&buffer[..n]);

    let mut lines = request_str.lines();
    let first_line = lines.next().unwrap_or("");
    let parts: Vec<&str> = first_line.split_whitespace().collect();
    if parts.len() < 2 {
        return;
    }
    let method = parts[0];
    let path = parts[1];

    if method == "OPTIONS" {
        let resp = "HTTP/1.1 204 No Content\r\nAccess-Control-Allow-Origin: *\r\nAccess-Control-Allow-Methods: GET, POST, OPTIONS\r\nAccess-Control-Allow-Headers: *\r\nContent-Length: 0\r\nConnection: close\r\n\r\n";
        let _ = stream.write_all(resp.as_bytes()).await;
        return;
    }

    if method == "GET" && path.starts_with("/api/ping") {
        let dname = device_name.lock().unwrap().clone();
        let body = serde_json::json!({
            "status": "ok",
            "device": dname,
            "platform": "Desktop (Windows)"
        })
        .to_string();
        let resp = format!(
            "HTTP/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
            body.len(), body
        );
        let _ = stream.write_all(resp.as_bytes()).await;
        return;
    }

    if method == "GET" && path.starts_with("/api/local-ip") {
        let ip = get_lan_ip();
        let body = serde_json::json!({
            "ip": ip
        })
        .to_string();
        let resp = format!(
            "HTTP/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
            body.len(), body
        );
        let _ = stream.write_all(resp.as_bytes()).await;
        return;
    }

    if method == "POST" && path.starts_with("/api/sync") {
        if let Some(pos) = request_str.find("\r\n\r\n") {
            let body_str = &request_str[pos + 4..];
            if let Ok(val) = serde_json::from_str::<serde_json::Value>(body_str) {
                if let Some(text) = val.get("text").and_then(|t| t.as_str()) {
                    let text = text.to_string();
                    let origin = val
                        .get("origin")
                        .and_then(|o| o.as_str())
                        .unwrap_or("Remote Companion");

                    let hash = protocol::sha256_str(&text);
                    {
                        let mut last = last_synced_hash.lock().unwrap();
                        *last = hash.clone();
                    }

                    // Set Windows Clipboard
                    if let Ok(mut cb) = arboard::Clipboard::new() {
                        let _ = cb.set_text(&text);
                    }

                    // Save to history DB
                    {
                        let db_lock = db.lock().unwrap();
                        let now = chrono_now_ms();
                        let item = StoredHistoryItem {
                            id: format!("hist_{}", hex::encode(rand::random::<[u8; 8]>())),
                            content_type: clipboard::detect_content_type(&text),
                            text_data: text.clone(),
                            content_hash: hash,
                            origin_device_id: origin.to_string(),
                            timestamp: now,
                            is_pinned: false,
                            is_sensitive: clipboard::is_sensitive_content(&text),
                        };
                        let _ = db_lock.add_history_item(&item);
                    }

                    let resp_body = serde_json::json!({ "status": "synced" }).to_string();
                    let resp = format!(
                        "HTTP/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
                        resp_body.len(), resp_body
                    );
                    let _ = stream.write_all(resp.as_bytes()).await;
                    return;
                }
            }
        }
    }

    let not_found = "HTTP/1.1 404 Not Found\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: 0\r\nConnection: close\r\n\r\n";
    let _ = stream.write_all(not_found.as_bytes()).await;
}

async fn run_lan_http_server(
    db: Arc<Mutex<Database>>,
    device_name: Arc<Mutex<String>>,
    last_synced_hash: Arc<Mutex<String>>,
) {
    if let Ok(listener) = TcpListener::bind("0.0.0.0:48901").await {
        while let Ok((stream, _)) = listener.accept().await {
            let db_c = Arc::clone(&db);
            let dev_c = Arc::clone(&device_name);
            let hash_c = Arc::clone(&last_synced_hash);
            tokio::spawn(async move {
                handle_http_connection(stream, db_c, dev_c, hash_c).await;
            });
        }
    }
}

async fn run_clipboard_monitor(
    db: Arc<Mutex<Database>>,
    device_name: Arc<Mutex<String>>,
    last_synced_hash: Arc<Mutex<String>>,
    companion_ip: Arc<Mutex<String>>,
) {
    // Real-time clipboard polling (250ms for instant synchronization)
    let mut interval = tokio::time::interval(std::time::Duration::from_millis(250));
    loop {
        interval.tick().await;

        let current_text = match arboard::Clipboard::new() {
            Ok(mut cb) => cb.get_text().ok(),
            Err(_) => None,
        };

        if let Some(text) = current_text {
            let trimmed = text.trim();
            if !trimmed.is_empty() {
                let hash = protocol::sha256_str(trimmed);
                let should_sync = {
                    let mut last = last_synced_hash.lock().unwrap();
                    if *last != hash {
                        *last = hash.clone();
                        true
                    } else {
                        false
                    }
                };

                if should_sync {
                    // Save to history db
                    {
                        let db_lock = db.lock().unwrap();
                        let now = chrono_now_ms();
                        let item = StoredHistoryItem {
                            id: format!("hist_{}", hex::encode(rand::random::<[u8; 8]>())),
                            content_type: clipboard::detect_content_type(trimmed),
                            text_data: trimmed.to_string(),
                            content_hash: hash,
                            origin_device_id: device_name.lock().unwrap().clone(),
                            timestamp: now,
                            is_pinned: false,
                            is_sensitive: clipboard::is_sensitive_content(trimmed),
                        };
                        let _ = db_lock.add_history_item(&item);
                    }

                    // Dispatch to companion IP if set
                    let comp_ip = companion_ip.lock().unwrap().clone();
                    if !comp_ip.is_empty() {
                        let origin = device_name.lock().unwrap().clone();
                        let text_clone = trimmed.to_string();
                        tokio::spawn(async move {
                            send_sync_to_ip(&comp_ip, &text_clone, &origin).await;
                        });
                    }
                }
            }
        }
    }
}

fn main() {
    let db = Arc::new(Mutex::new(
        Database::new_file("clipsync.db")
            .unwrap_or_else(|_| Database::new_in_memory().expect("in-memory db fallback")),
    ));

    // Load or generate identity
    let (identity, device_id, device_name) = {
        let db_lock = db.lock().unwrap();
        if let Ok(Some(existing)) = db_lock.get_identity() {
            let mut s_seed = [0u8; 32];
            let mut x_seed = [0u8; 32];
            s_seed.copy_from_slice(&existing.signing_seed);
            x_seed.copy_from_slice(&existing.exchange_seed);
            let id = IdentityKeyPair::from_seeds(&s_seed, &x_seed);
            (id, existing.device_id, existing.device_name)
        } else {
            let id = IdentityKeyPair::generate();
            let dev_id = id.device_id();
            let dev_name = format!("Desktop-Win-{}", &dev_id[0..4].to_uppercase());

            let stored = StoredDeviceIdentity {
                device_id: dev_id.clone(),
                device_name: dev_name.clone(),
                signing_seed: id.signing_key.to_bytes().to_vec(),
                exchange_seed: id.exchange_secret.to_bytes().to_vec(),
                created_at: chrono_now_ms(),
            };
            let _ = db_lock.save_identity(&stored);
            (id, dev_id, dev_name)
        }
    };

    let initial_device_name = {
        let db_lock = db.lock().unwrap();
        let custom = db_lock.get_setting("device_name", "");
        if !custom.is_empty() {
            custom
        } else {
            device_name
        }
    };

    let initial_companion_ip = {
        let db_lock = db.lock().unwrap();
        db_lock.get_setting("companion_ip", "")
    };

    let dev_name_arc = Arc::new(Mutex::new(initial_device_name));
    let comp_ip_arc = Arc::new(Mutex::new(initial_companion_ip));
    let last_hash_arc = Arc::new(Mutex::new(String::new()));

    // Spawn dedicated background thread with Tokio runtime for LAN server & clipboard watcher
    let db_bg = Arc::clone(&db);
    let dev_name_bg = Arc::clone(&dev_name_arc);
    let last_hash_bg = Arc::clone(&last_hash_arc);
    let comp_ip_bg = Arc::clone(&comp_ip_arc);

    std::thread::spawn(move || {
        if let Ok(rt) = tokio::runtime::Builder::new_multi_thread()
            .enable_all()
            .build()
        {
            rt.block_on(async move {
                let db_lan = Arc::clone(&db_bg);
                let dev_lan = Arc::clone(&dev_name_bg);
                let hash_lan = Arc::clone(&last_hash_bg);
                tokio::spawn(async move {
                    run_lan_http_server(db_lan, dev_lan, hash_lan).await;
                });

                run_clipboard_monitor(db_bg, dev_name_bg, last_hash_bg, comp_ip_bg).await;
            });
        }
    });

    let app_state = AppState {
        db,
        identity: Arc::new(Mutex::new(identity)),
        device_name: dev_name_arc,
        device_id,
        active_pairing_session: Arc::new(Mutex::new(None)),
        companion_ip: comp_ip_arc,
        last_synced_hash: last_hash_arc,
    };

    tauri::Builder::default()
        .manage(app_state)
        .setup(|app| {
            if let Some(window) = app.get_webview_window("main") {
                let _ = window.show();
                let _ = window.set_focus();
            }
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            get_device_identity,
            update_device_name,
            generate_pairing_qr,
            confirm_pairing,
            get_paired_devices,
            revoke_device,
            get_clipboard_history,
            add_local_history_item,
            clear_history,
            get_connection_status,
            get_local_ip,
            get_companion_ip,
            set_companion_ip,
            sync_clipboard_now,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
