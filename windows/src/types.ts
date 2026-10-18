export interface DeviceInfo {
  device_id: string;
  device_name: string;
  ed25519_pubkey: string;
  x25519_pubkey: string;
}

export interface PairedDevice {
  device_id: string;
  device_name: string;
  ed25519_pubkey: string;
  x25519_pubkey: string;
  paired_at: number;
  last_seen: number;
  is_revoked: boolean;
  is_online?: boolean;
  connection_mode?: 'LOCAL' | 'P2P' | 'RELAY' | 'OFFLINE';
}

export interface PairingPayload {
  session_id: string;
  device_id: string;
  device_name: string;
  ed25519_pubkey: string;
  x25519_pubkey: string;
  sas_code: string;
  ip_hints: string[];
  port: number;
  expires_at: number;
}

export interface HistoryItem {
  id: string;
  content_type: string;
  text_data: string;
  content_hash: string;
  origin_device_id: string;
  timestamp: number;
  is_pinned: boolean;
  is_sensitive: boolean;
}

export interface ConnectionStatus {
  state: 'DISCOVERING' | 'PAIRING' | 'CONNECTING_LOCAL' | 'CONNECTED_DIRECT' | 'CONNECTED_RELAY' | 'OFFLINE' | 'ERROR';
  transport_mode: string;
  active_peer_count: number;
  ping_ms: number;
  bytes_sent: number;
  bytes_received: number;
}

export interface AppSettings {
  networkMode: 'hybrid' | 'local_only' | 'remote_only';
  signalingUrl: string;
  relayUrl: string;
  autoSync: boolean;
  syncImages: boolean;
  maxFileSizeMb: number;
  historyRetentionCount: number;
  sensitiveFilterEnabled: boolean;
}
