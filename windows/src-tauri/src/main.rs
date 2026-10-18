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

struct AppState {
    db: Arc<Mutex<Database>>,
    identity: Arc<Mutex<IdentityKeyPair>>,
    device_name: String,
    device_id: String,
    active_pairing_session: Arc<Mutex<Option<protocol::PairingPayload>>>,
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
    DeviceInfo {
        device_id: state.device_id.clone(),
        device_name: state.device_name.clone(),
        ed25519_pubkey: id.ed25519_pubkey_hex(),
        x25519_pubkey: id.x25519_pubkey_hex(),
    }
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
        device_name: state.device_name.clone(),
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
    let state_str = if active_peers.is_empty() {
        "PAIRING"
    } else {
        "CONNECTED_DIRECT"
    };

    ConnectionStatus {
        state: state_str.to_string(),
        transport_mode: if active_peers.is_empty() {
            "DISCOVERING".to_string()
        } else {
            "LOCAL_WIFI".to_string()
        },
        active_peer_count: active_peers.len(),
        ping_ms: 12,
        bytes_sent: 4096,
        bytes_received: 8192,
    }
}

fn chrono_now_ms() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis() as i64
}

fn main() {
    let db = Arc::new(Mutex::new(
        Database::new_file("clipsync.db").unwrap_or_else(|_| {
            Database::new_in_memory().expect("in-memory db fallback")
        }),
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
            let dev_name = format!(
                "Desktop-Win-{}",
                &dev_id[0..4].to_uppercase()
            );

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

    let app_state = AppState {
        db,
        identity: Arc::new(Mutex::new(identity)),
        device_name,
        device_id,
        active_pairing_session: Arc::new(Mutex::new(None)),
    };

    tauri::Builder::default()
        .manage(app_state)
        .invoke_handler(tauri::generate_handler![
            get_device_identity,
            generate_pairing_qr,
            confirm_pairing,
            get_paired_devices,
            revoke_device,
            get_clipboard_history,
            add_local_history_item,
            clear_history,
            get_connection_status,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
