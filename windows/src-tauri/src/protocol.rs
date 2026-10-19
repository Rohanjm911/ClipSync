//! Wire Protocol, Loop Prevention, and Conflict Resolution for Rust Core

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

pub const PROTOCOL_VERSION: u32 = 1;
pub const PAIRING_EXPIRATION_MS: i64 = 180 * 1000; // 3 minutes

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum MessageType {
    PairingRequest,
    PairingAccept,
    PairingReject,
    ClipboardSync,
    ClipboardAck,
    FileOffer,
    FileAccept,
    FileReject,
    FileChunk,
    FileComplete,
    Revocation,
    Ping,
    Pong,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PairingPayload {
    pub session_id: String,
    pub device_id: String,
    pub device_name: String,
    pub ed25519_pubkey: String,
    pub x25519_pubkey: String,
    pub sas_code: String,
    pub ip_hints: Vec<String>,
    pub port: u16,
    pub expires_at: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClipboardPayload {
    pub event_id: String,
    pub origin_device_id: String,
    pub content_type: String,
    pub data: String,
    pub timestamp: i64,
}

/// Compute SHA-256 hash of a string
pub fn sha256_str(s: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(s.as_bytes());
    hex::encode(hasher.finalize())
}

/// Create unique Event ID for loop prevention
pub fn create_event_id(origin_device_id: &str, counter: u64, content_hash: &str) -> String {
    let raw = format!("{}:{}:{}", origin_device_id, counter, content_hash);
    sha256_str(&raw)
}

/// Deterministic Conflict Resolution Matrix
/// Returns true if incoming event should supersede local event
pub fn should_incoming_win(
    local_timestamp: i64,
    local_origin: &str,
    incoming_timestamp: i64,
    incoming_origin: &str,
) -> bool {
    // 1. Timestamp precedence
    if incoming_timestamp > local_timestamp {
        return true;
    }
    if incoming_timestamp < local_timestamp {
        return false;
    }
    // 2. Lexicographical tie-breaker
    incoming_origin > local_origin
}

/// Sanitize file names to prevent path traversal
pub fn sanitize_filename(filename: &str) -> String {
    let clean = filename.replace('\0', "");
    let clean = clean.replace('\\', "/");
    let parts: Vec<&str> = clean.split('/').filter(|s| !s.is_empty()).collect();
    let base = parts.last().copied().unwrap_or("unnamed_file");
    let base = base.trim_start_matches('.');

    let mut sanitized = String::new();
    for c in base.chars() {
        if matches!(c, '<' | '>' | ':' | '"' | '/' | '\\' | '|' | '?' | '*') {
            sanitized.push('_');
        } else {
            sanitized.push(c);
        }
    }
    let sanitized = sanitized.trim();
    if sanitized.is_empty() || sanitized == "." || sanitized == ".." {
        "unnamed_file".to_string()
    } else {
        sanitized.chars().take(255).collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_conflict_resolution() {
        assert!(should_incoming_win(100, "dev_a", 150, "dev_b"));
        assert!(!should_incoming_win(150, "dev_a", 100, "dev_b"));

        // Tie-breaker
        assert!(should_incoming_win(100, "dev_a", 100, "dev_b"));
        assert!(!should_incoming_win(100, "dev_b", 100, "dev_a"));
    }

    #[test]
    fn test_filename_sanitization() {
        assert_eq!(sanitize_filename("../../passwd"), "passwd");
        assert_eq!(sanitize_filename("..\\..\\calc.exe"), "calc.exe");
        assert_eq!(
            sanitize_filename("test<file>:name?.png"),
            "test_file__name_.png"
        );
        assert_eq!(sanitize_filename(""), "unnamed_file");
    }
}
