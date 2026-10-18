/**
 * ClipSync Wire Protocol & Schema Definitions
 * Protocol Version: 1
 */

const crypto = require('crypto');

const PROTOCOL_VERSION = 1;
const DEFAULT_LOCAL_PORT = 48901;
const DEFAULT_BROADCAST_PORT = 48902;
const PAIRING_EXPIRATION_MS = 180 * 1000; // 3 minutes

const MessageType = Object.freeze({
  PAIRING_REQUEST: 'PAIRING_REQUEST',
  PAIRING_ACCEPT: 'PAIRING_ACCEPT',
  PAIRING_REJECT: 'PAIRING_REJECT',
  CLIPBOARD_SYNC: 'CLIPBOARD_SYNC',
  CLIPBOARD_ACK: 'CLIPBOARD_ACK',
  FILE_OFFER: 'FILE_OFFER',
  FILE_ACCEPT: 'FILE_ACCEPT',
  FILE_REJECT: 'FILE_REJECT',
  FILE_CHUNK: 'FILE_CHUNK',
  FILE_COMPLETE: 'FILE_COMPLETE',
  REVOCATION: 'REVOCATION',
  PING: 'PING',
  PONG: 'PONG',
});

const ContentType = Object.freeze({
  TEXT_PLAIN: 'text/plain',
  TEXT_URI_LIST: 'text/uri-list',
  IMAGE_PNG: 'image/png',
  IMAGE_JPEG: 'image/jpeg',
  IMAGE_WEBP: 'image/webp',
  APPLICATION_OCTET_STREAM: 'application/octet-stream',
});

const ConnectionState = Object.freeze({
  DISCOVERING: 'DISCOVERING',
  PAIRING: 'PAIRING',
  CONNECTING_LOCAL: 'CONNECTING_LOCAL',
  CONNECTING_REMOTE: 'CONNECTING_REMOTE',
  CONNECTED_DIRECT: 'CONNECTED_DIRECT',
  CONNECTED_RELAY: 'CONNECTED_RELAY',
  RECONNECTING: 'RECONNECTING',
  OFFLINE: 'OFFLINE',
  ERROR: 'ERROR',
});

const path = require('path');

/**
 * Sanitize filename to prevent directory traversal and illegal characters
 */
function sanitizeFilename(filename) {
  if (typeof filename !== 'string') return 'unnamed_file';
  // Strip null bytes
  let clean = filename.replace(/\0/g, '');
  // Normalize slashes and take basename
  clean = clean.replace(/\\/g, '/');
  // Strip any sequence of ../ or ./
  clean = clean.split('/').filter(Boolean).pop() || '';
  // Remove any remaining traversal patterns
  clean = clean.replace(/^\.+/, '');
  // Strip illegal Windows and POSIX characters: < > : " / \ | ? *
  clean = clean.replace(/[<>:"/\\|?*]/g, '_');
  clean = clean.trim();
  if (clean.length === 0 || clean === '.' || clean === '..') {
    return 'unnamed_file';
  }
  return clean.substring(0, 255);
}

/**
 * Compute SHA-256 hash of a string or buffer
 */
function sha256(data) {
  return crypto.createHash('sha256').update(data).digest('hex');
}

/**
 * Derive 6-digit Short Authentication String (SAS) from shared secret and exchange nonces
 */
function deriveSASCode(sharedSecret, nonceA, nonceB) {
  const hmac = crypto.createHmac('sha256', sharedSecret);
  hmac.update(Buffer.from(nonceA, 'hex'));
  hmac.update(Buffer.from(nonceB, 'hex'));
  const digest = hmac.digest();
  // Take first 4 bytes as unsigned integer mod 1,000,000
  const num = digest.readUInt32BE(0) % 1000000;
  return num.toString().padStart(6, '0');
}

/**
 * Generate a monotonic unique Event ID for loop prevention
 */
function createEventId(originDeviceId, counter, contentHash) {
  return sha256(`${originDeviceId}:${counter}:${contentHash}`);
}

/**
 * Deterministic Conflict Resolution Matrix
 * Returns true if incoming event should overwrite local event
 */
function shouldIncomingEventWin(localEvent, incomingEvent) {
  if (!localEvent) return true;
  if (!incomingEvent) return false;

  // 1. Monotonic timestamp comparison
  if (incomingEvent.timestamp > localEvent.timestamp) {
    return true;
  }
  if (incomingEvent.timestamp < localEvent.timestamp) {
    return false;
  }

  // 2. Tie-breaker: Lexicographical comparison of device IDs
  return incomingEvent.originDeviceId > localEvent.originDeviceId;
}

/**
 * Validate Pairing Token expiration
 */
function isPairingPayloadValid(payload) {
  if (!payload || typeof payload !== 'object') return false;
  const { sessionId, deviceId, deviceName, ed25519PubKey, x25519PubKey, expiresAt } = payload;
  if (!sessionId || !deviceId || !deviceName || !ed25519PubKey || !x25519PubKey || !expiresAt) {
    return false;
  }
  const now = Date.now();
  if (now > expiresAt) {
    return false; // Expired
  }
  // Enforce reasonable max expiration window (cannot be > 5 minutes in future)
  if (expiresAt - now > 5 * 60 * 1000) {
    return false;
  }
  return true;
}

/**
 * Validate Clipboard Payload
 */
function validateClipboardPayload(payload) {
  if (!payload || typeof payload !== 'object') return { valid: false, error: 'Malformed payload' };
  if (!payload.eventId || typeof payload.eventId !== 'string') return { valid: false, error: 'Missing eventId' };
  if (!payload.originDeviceId || typeof payload.originDeviceId !== 'string') return { valid: false, error: 'Missing originDeviceId' };
  if (!payload.contentType || !Object.values(ContentType).includes(payload.contentType)) {
    return { valid: false, error: 'Unsupported or missing contentType' };
  }
  if (typeof payload.data !== 'string') return { valid: false, error: 'Payload data must be a string' };
  if (typeof payload.timestamp !== 'number') return { valid: false, error: 'Invalid timestamp' };
  if (payload.data.length > 25 * 1024 * 1024) { // 25MB max cap for clipboard
    return { valid: false, error: 'Clipboard payload exceeds size cap' };
  }
  return { valid: true };
}

/**
 * Validate File Transfer Offer
 */
function validateFileOffer(offer) {
  if (!offer || typeof offer !== 'object') return { valid: false, error: 'Malformed offer' };
  if (!offer.transferId || typeof offer.transferId !== 'string') return { valid: false, error: 'Missing transferId' };
  if (!offer.fileName || typeof offer.fileName !== 'string') return { valid: false, error: 'Missing fileName' };
  if (typeof offer.fileSize !== 'number' || offer.fileSize < 0) return { valid: false, error: 'Invalid fileSize' };
  if (!offer.sha256Hash || offer.sha256Hash.length !== 64) return { valid: false, error: 'Invalid sha256Hash' };
  return { valid: true };
}

module.exports = {
  PROTOCOL_VERSION,
  DEFAULT_LOCAL_PORT,
  DEFAULT_BROADCAST_PORT,
  PAIRING_EXPIRATION_MS,
  MessageType,
  ContentType,
  ConnectionState,
  sanitizeFilename,
  sha256,
  deriveSASCode,
  createEventId,
  shouldIncomingEventWin,
  isPairingPayloadValid,
  validateClipboardPayload,
  validateFileOffer,
};
