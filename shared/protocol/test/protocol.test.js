const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  sanitizeFilename,
  sha256,
  deriveSASCode,
  createEventId,
  shouldIncomingEventWin,
  isPairingPayloadValid,
  validateClipboardPayload,
  validateFileOffer,
  ContentType,
} = require('../index.js');

describe('ClipSync Shared Protocol Tests', () => {
  describe('Path Traversal & Filename Sanitization', () => {
    it('should strip path traversal sequences', () => {
      assert.equal(sanitizeFilename('../../evil.exe'), 'evil.exe');
      assert.equal(sanitizeFilename('..\\..\\windows\\system32\\calc.exe'), 'calc.exe');
    });

    it('should sanitize illegal characters on Windows and POSIX', () => {
      assert.equal(sanitizeFilename('my<cool>:file*name?.txt'), 'my_cool__file_name_.txt');
      assert.equal(sanitizeFilename('   padded_name.png   '), 'padded_name.png');
    });

    it('should handle empty or null filename safely', () => {
      assert.equal(sanitizeFilename(''), 'unnamed_file');
      assert.equal(sanitizeFilename(null), 'unnamed_file');
      assert.equal(sanitizeFilename('...'), 'unnamed_file');
    });
  });

  describe('Pairing Payload Validation & Expiration', () => {
    it('should accept valid non-expired pairing payload', () => {
      const validPayload = {
        sessionId: 'sess_123',
        deviceId: 'dev_abc',
        deviceName: 'Pixel 8',
        ed25519PubKey: 'pub_ed_123',
        x25519PubKey: 'pub_x_456',
        expiresAt: Date.now() + 60000,
      };
      assert.equal(isPairingPayloadValid(validPayload), true);
    });

    it('should reject expired pairing payload', () => {
      const expiredPayload = {
        sessionId: 'sess_123',
        deviceId: 'dev_abc',
        deviceName: 'Pixel 8',
        ed25519PubKey: 'pub_ed_123',
        x25519PubKey: 'pub_x_456',
        expiresAt: Date.now() - 5000, // 5 seconds in the past
      };
      assert.equal(isPairingPayloadValid(expiredPayload), false);
    });

    it('should reject payload with missing required fields', () => {
      assert.equal(isPairingPayloadValid({ sessionId: '123' }), false);
      assert.equal(isPairingPayloadValid(null), false);
    });
  });

  describe('Conflict Resolution Matrix', () => {
    it('should allow newer timestamp to win over older timestamp', () => {
      const local = { timestamp: 1000, originDeviceId: 'dev_A' };
      const incoming = { timestamp: 1050, originDeviceId: 'dev_B' };
      assert.equal(shouldIncomingEventWin(local, incoming), true);

      const olderIncoming = { timestamp: 950, originDeviceId: 'dev_B' };
      assert.equal(shouldIncomingEventWin(local, olderIncoming), false);
    });

    it('should resolve equal timestamps deterministically using device ID tie-breaker', () => {
      const local = { timestamp: 2000, originDeviceId: 'dev_001' };
      const incomingGreater = { timestamp: 2000, originDeviceId: 'dev_002' };
      assert.equal(shouldIncomingEventWin(local, incomingGreater), true);

      const incomingLesser = { timestamp: 2000, originDeviceId: 'dev_000' };
      assert.equal(shouldIncomingEventWin(local, incomingLesser), false);
    });
  });

  describe('Cryptographic Helpers & SAS Generation', () => {
    it('should derive deterministic 6-digit SAS code', () => {
      const secret = Buffer.alloc(32, 0x42);
      const nonceA = 'a'.repeat(64);
      const nonceB = 'b'.repeat(64);

      const code1 = deriveSASCode(secret, nonceA, nonceB);
      const code2 = deriveSASCode(secret, nonceA, nonceB);

      assert.equal(code1.length, 6);
      assert.match(code1, /^\d{6}$/);
      assert.equal(code1, code2);
    });

    it('should generate deterministic event ID for loop prevention', () => {
      const id1 = createEventId('dev_1', 1, 'hash_abc');
      const id2 = createEventId('dev_1', 1, 'hash_abc');
      const id3 = createEventId('dev_1', 2, 'hash_abc');

      assert.equal(id1, id2);
      assert.notEqual(id1, id3);
      assert.equal(id1.length, 64);
    });
  });

  describe('Payload Validation', () => {
    it('should validate valid clipboard payload', () => {
      const payload = {
        eventId: 'evt_123',
        originDeviceId: 'dev_1',
        contentType: ContentType.TEXT_PLAIN,
        data: 'Hello, ClipSync!',
        timestamp: Date.now(),
      };
      const res = validateClipboardPayload(payload);
      assert.equal(res.valid, true);
    });

    it('should reject invalid content type', () => {
      const payload = {
        eventId: 'evt_123',
        originDeviceId: 'dev_1',
        contentType: 'audio/mp3',
        data: '...',
        timestamp: Date.now(),
      };
      const res = validateClipboardPayload(payload);
      assert.equal(res.valid, false);
    });

    it('should validate file offer with valid SHA-256', () => {
      const offer = {
        transferId: 'xfer_1',
        fileName: 'report.pdf',
        fileSize: 1048576,
        sha256Hash: sha256('dummy-content'),
      };
      const res = validateFileOffer(offer);
      assert.equal(res.valid, true);
    });
  });
});
