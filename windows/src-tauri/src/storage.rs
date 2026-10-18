//! SQLite Storage Layer for ClipSync Windows Desktop
//! Manages persistent device identity, paired peers, local clipboard history, and configuration.

use rusqlite::{params, Connection, Result};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StoredDeviceIdentity {
    pub device_id: String,
    pub device_name: String,
    pub signing_seed: Vec<u8>,
    pub exchange_seed: Vec<u8>,
    pub created_at: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StoredPairedDevice {
    pub device_id: String,
    pub device_name: String,
    pub ed25519_pubkey: String,
    pub x25519_pubkey: String,
    pub paired_at: i64,
    pub last_seen: i64,
    pub is_revoked: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StoredHistoryItem {
    pub id: String,
    pub content_type: String,
    pub text_data: String,
    pub content_hash: String,
    pub origin_device_id: String,
    pub timestamp: i64,
    pub is_pinned: bool,
    pub is_sensitive: bool,
}

pub struct Database {
    conn: Connection,
}

impl Database {
    /// Initialize an in-memory database (for testing) or on-disk database
    pub fn new_in_memory() -> Result<Self> {
        let conn = Connection::open_in_memory()?;
        let db = Self { conn };
        db.create_tables()?;
        Ok(db)
    }

    pub fn new_file(path: &str) -> Result<Self> {
        let conn = Connection::open(path)?;
        let db = Self { conn };
        db.create_tables()?;
        Ok(db)
    }

    fn create_tables(&self) -> Result<()> {
        self.conn.execute_batch(
            "
            CREATE TABLE IF NOT EXISTS device_identity (
                id INTEGER PRIMARY KEY CHECK (id = 1),
                device_id TEXT NOT NULL,
                device_name TEXT NOT NULL,
                signing_seed BLOB NOT NULL,
                exchange_seed BLOB NOT NULL,
                created_at INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS paired_devices (
                device_id TEXT PRIMARY KEY,
                device_name TEXT NOT NULL,
                ed25519_pubkey TEXT NOT NULL,
                x25519_pubkey TEXT NOT NULL,
                paired_at INTEGER NOT NULL,
                last_seen INTEGER NOT NULL,
                is_revoked INTEGER NOT NULL DEFAULT 0
            );

            CREATE TABLE IF NOT EXISTS clipboard_history (
                id TEXT PRIMARY KEY,
                content_type TEXT NOT NULL,
                text_data TEXT NOT NULL,
                content_hash TEXT NOT NULL,
                origin_device_id TEXT NOT NULL,
                timestamp INTEGER NOT NULL,
                is_pinned INTEGER NOT NULL DEFAULT 0,
                is_sensitive INTEGER NOT NULL DEFAULT 0
            );

            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            );
            ",
        )?;
        Ok(())
    }

    // --- Identity Operations ---

    pub fn get_identity(&self) -> Result<Option<StoredDeviceIdentity>> {
        let mut stmt = self.conn.prepare(
            "SELECT device_id, device_name, signing_seed, exchange_seed, created_at FROM device_identity WHERE id = 1",
        )?;
        let mut rows = stmt.query([])?;
        if let Some(row) = rows.next()? {
            Ok(Some(StoredDeviceIdentity {
                device_id: row.get(0)?,
                device_name: row.get(1)?,
                signing_seed: row.get(2)?,
                exchange_seed: row.get(3)?,
                created_at: row.get(4)?,
            }))
        } else {
            Ok(None)
        }
    }

    pub fn save_identity(&self, identity: &StoredDeviceIdentity) -> Result<()> {
        self.conn.execute(
            "INSERT OR REPLACE INTO device_identity (id, device_id, device_name, signing_seed, exchange_seed, created_at)
             VALUES (1, ?1, ?2, ?3, ?4, ?5)",
            params![
                identity.device_id,
                identity.device_name,
                identity.signing_seed,
                identity.exchange_seed,
                identity.created_at
            ],
        )?;
        Ok(())
    }

    // --- Paired Devices Operations ---

    pub fn get_paired_devices(&self) -> Result<Vec<StoredPairedDevice>> {
        let mut stmt = self.conn.prepare(
            "SELECT device_id, device_name, ed25519_pubkey, x25519_pubkey, paired_at, last_seen, is_revoked 
             FROM paired_devices WHERE is_revoked = 0 ORDER BY last_seen DESC",
        )?;
        let rows = stmt.query_map([], |row| {
            let is_revoked_int: i32 = row.get(6)?;
            Ok(StoredPairedDevice {
                device_id: row.get(0)?,
                device_name: row.get(1)?,
                ed25519_pubkey: row.get(2)?,
                x25519_pubkey: row.get(3)?,
                paired_at: row.get(4)?,
                last_seen: row.get(5)?,
                is_revoked: is_revoked_int != 0,
            })
        })?;

        let mut devices = Vec::new();
        for dev in rows {
            devices.push(dev?);
        }
        Ok(devices)
    }

    pub fn save_paired_device(&self, dev: &StoredPairedDevice) -> Result<()> {
        self.conn.execute(
            "INSERT OR REPLACE INTO paired_devices (device_id, device_name, ed25519_pubkey, x25519_pubkey, paired_at, last_seen, is_revoked)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
            params![
                dev.device_id,
                dev.device_name,
                dev.ed25519_pubkey,
                dev.x25519_pubkey,
                dev.paired_at,
                dev.last_seen,
                if dev.is_revoked { 1 } else { 0 }
            ],
        )?;
        Ok(())
    }

    pub fn revoke_device(&self, device_id: &str) -> Result<()> {
        self.conn.execute(
            "UPDATE paired_devices SET is_revoked = 1 WHERE device_id = ?1",
            params![device_id],
        )?;
        Ok(())
    }

    // --- Clipboard History Operations ---

    pub fn add_history_item(&self, item: &StoredHistoryItem) -> Result<()> {
        self.conn.execute(
            "INSERT OR REPLACE INTO clipboard_history (id, content_type, text_data, content_hash, origin_device_id, timestamp, is_pinned, is_sensitive)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
            params![
                item.id,
                item.content_type,
                item.text_data,
                item.content_hash,
                item.origin_device_id,
                item.timestamp,
                if item.is_pinned { 1 } else { 0 },
                if item.is_sensitive { 1 } else { 0 }
            ],
        )?;
        Ok(())
    }

    pub fn get_history(&self, limit: usize) -> Result<Vec<StoredHistoryItem>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, content_type, text_data, content_hash, origin_device_id, timestamp, is_pinned, is_sensitive 
             FROM clipboard_history ORDER BY is_pinned DESC, timestamp DESC LIMIT ?1",
        )?;
        let rows = stmt.query_map(params![limit as i64], |row| {
            let is_pinned_int: i32 = row.get(6)?;
            let is_sensitive_int: i32 = row.get(7)?;
            Ok(StoredHistoryItem {
                id: row.get(0)?,
                content_type: row.get(1)?,
                text_data: row.get(2)?,
                content_hash: row.get(3)?,
                origin_device_id: row.get(4)?,
                timestamp: row.get(5)?,
                is_pinned: is_pinned_int != 0,
                is_sensitive: is_sensitive_int != 0,
            })
        })?;

        let mut history = Vec::new();
        for item in rows {
            history.push(item?);
        }
        Ok(history)
    }

    pub fn clear_unpinned_history(&self) -> Result<()> {
        self.conn.execute(
            "DELETE FROM clipboard_history WHERE is_pinned = 0",
            [],
        )?;
        Ok(())
    }

    // --- Settings Operations ---

    pub fn get_setting(&self, key: &str, default_value: &str) -> String {
        let res: Result<String> = self.conn.query_row(
            "SELECT value FROM settings WHERE key = ?1",
            params![key],
            |row| row.get(0),
        );
        res.unwrap_or_else(|_| default_value.to_string())
    }

    pub fn set_setting(&self, key: &str, value: &str) -> Result<()> {
        self.conn.execute(
            "INSERT OR REPLACE INTO settings (key, value) VALUES (?1, ?2)",
            params![key, value],
        )?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_storage_lifecycle() {
        let db = Database::new_in_memory().expect("in-memory db");

        // Identity
        assert!(db.get_identity().unwrap().is_none());
        let identity = StoredDeviceIdentity {
            device_id: "test_dev_01".to_string(),
            device_name: "Desktop-PC".to_string(),
            signing_seed: vec![1; 32],
            exchange_seed: vec![2; 32],
            created_at: 1000,
        };
        db.save_identity(&identity).unwrap();
        let loaded_id = db.get_identity().unwrap().expect("identity present");
        assert_eq!(loaded_id.device_id, "test_dev_01");

        // Pairing & Revocation
        let peer = StoredPairedDevice {
            device_id: "phone_01".to_string(),
            device_name: "Galaxy S24".to_string(),
            ed25519_pubkey: "hex_pub_1".to_string(),
            x25519_pubkey: "hex_pub_2".to_string(),
            paired_at: 2000,
            last_seen: 2050,
            is_revoked: false,
        };
        db.save_paired_device(&peer).unwrap();
        let active_peers = db.get_paired_devices().unwrap();
        assert_eq!(active_peers.len(), 1);

        // Revoke
        db.revoke_device("phone_01").unwrap();
        let active_peers_after = db.get_paired_devices().unwrap();
        assert_eq!(active_peers_after.len(), 0);

        // History
        let hist = StoredHistoryItem {
            id: "hist_01".to_string(),
            content_type: "text/plain".to_string(),
            text_data: "Hello world".to_string(),
            content_hash: "hash_01".to_string(),
            origin_device_id: "phone_01".to_string(),
            timestamp: 3000,
            is_pinned: false,
            is_sensitive: false,
        };
        db.add_history_item(&hist).unwrap();
        assert_eq!(db.get_history(10).unwrap().len(), 1);

        db.clear_unpinned_history().unwrap();
        assert_eq!(db.get_history(10).unwrap().len(), 0);
    }
}
