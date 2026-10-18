export const PROTOCOL_VERSION: number;
export const DEFAULT_LOCAL_PORT: number;
export const DEFAULT_BROADCAST_PORT: number;
export const PAIRING_EXPIRATION_MS: number;

export enum MessageType {
  PAIRING_REQUEST = 'PAIRING_REQUEST',
  PAIRING_ACCEPT = 'PAIRING_ACCEPT',
  PAIRING_REJECT = 'PAIRING_REJECT',
  CLIPBOARD_SYNC = 'CLIPBOARD_SYNC',
  CLIPBOARD_ACK = 'CLIPBOARD_ACK',
  FILE_OFFER = 'FILE_OFFER',
  FILE_ACCEPT = 'FILE_ACCEPT',
  FILE_REJECT = 'FILE_REJECT',
  FILE_CHUNK = 'FILE_CHUNK',
  FILE_COMPLETE = 'FILE_COMPLETE',
  REVOCATION = 'REVOCATION',
  PING = 'PING',
  PONG = 'PONG',
}

export enum ContentType {
  TEXT_PLAIN = 'text/plain',
  TEXT_URI_LIST = 'text/uri-list',
  IMAGE_PNG = 'image/png',
  IMAGE_JPEG = 'image/jpeg',
  IMAGE_WEBP = 'image/webp',
  APPLICATION_OCTET_STREAM = 'application/octet-stream',
}

export enum ConnectionState {
  DISCOVERING = 'DISCOVERING',
  PAIRING = 'PAIRING',
  CONNECTING_LOCAL = 'CONNECTING_LOCAL',
  CONNECTING_REMOTE = 'CONNECTING_REMOTE',
  CONNECTED_DIRECT = 'CONNECTED_DIRECT',
  CONNECTED_RELAY = 'CONNECTED_RELAY',
  RECONNECTING = 'RECONNECTING',
  OFFLINE = 'OFFLINE',
  ERROR = 'ERROR',
}

export interface DeviceIdentity {
  deviceId: string;
  deviceName: string;
  ed25519PubKey: string;
  x25519PubKey: string;
  createdAt: number;
}

export interface PairedDevice {
  deviceId: string;
  deviceName: string;
  ed25519PubKey: string;
  x25519PubKey: string;
  pairedAt: number;
  lastSeen: number;
  isOnline: boolean;
  connectionMode: 'LOCAL' | 'P2P' | 'RELAY' | 'OFFLINE';
}

export interface PairingPayload {
  sessionId: string;
  deviceId: string;
  deviceName: string;
  ed25519PubKey: string;
  x25519PubKey: string;
  sasCode: string;
  ipHints: string[];
  port: number;
  expiresAt: number;
}

export interface ClipboardPayload {
  eventId: string;
  originDeviceId: string;
  contentType: ContentType;
  data: string;
  timestamp: number;
}

export interface FileOffer {
  transferId: string;
  originDeviceId: string;
  fileName: string;
  fileSize: number;
  sha256Hash: string;
  mimeType: string;
}

export interface HistoryItem {
  id: string;
  contentType: ContentType;
  data: string;
  timestamp: number;
  originDeviceId: string;
  isPinned: boolean;
  isSensitive: boolean;
}

export function sanitizeFilename(filename: string): string;
export function sha256(data: string | Buffer): string;
export function deriveSASCode(sharedSecret: Buffer, nonceA: string, nonceB: string): string;
export function createEventId(originDeviceId: string, counter: number, contentHash: string): string;
export function shouldIncomingEventWin(localEvent: any, incomingEvent: any): boolean;
export function isPairingPayloadValid(payload: any): boolean;
export function validateClipboardPayload(payload: any): { valid: boolean; error?: string };
export function validateFileOffer(offer: any): { valid: boolean; error?: string };
