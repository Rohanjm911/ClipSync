# ClipSync Testing & Verification Plan (`TESTING.md`)

## 1. Testing Philosophy
Every core component in ClipSync must have automated test coverage before being marked as Implemented or Tested in `FEATURES.md`. Fake test claims are strictly forbidden.

---

## 2. Test Suites

### 2.1 Cryptographic & Protocol Tests (`shared/protocol`)
- Key generation sanity check (Ed25519 & X25519 public key derivation).
- Mutual signature generation and verification.
- Diffie-Hellman key exchange and HKDF derivation symmetry.
- ChaCha20-Poly1305 authenticated encryption & tampering detection (bit flip on ciphertext or auth tag must result in authentication failure).
- Replay attack detection with monotonic counters and timestamp validation.

### 2.2 Clipboard Synchronization & Loop Prevention Tests (`windows/src-tauri` & `android/app`)
- Hash calculation invariance across line-endings (`\r\n` vs `\n`).
- Loop prevention test: Ingesting an incoming remote payload must NOT re-emit a synchronization event.
- Concurrent clipboard race condition test: Deterministic conflict resolution matrix verification.
- Sensitive content detection test: Credit card regex, private key detection, password manager metadata parsing.

### 2.3 File Transfer & Integrity Tests
- Chunk stream assembly and disassembly.
- Path traversal prevention test (filenames containing `../`, `C:\`, `\etc\passwd` are scrubbed).
- Hash verification test: Corrupted chunk induces transfer abortion and deletion of `.part` temporary file.

### 2.4 Network & Signaling Tests (`infrastructure/`)
- Client pairing handshake with expired token rejection.
- WebSocket signaling room isolation.
- Relay forwarding with simulated packet latency and drop recovery.

---

## 3. Running Automated Tests

```bash
# Rust Unit & Integration Tests
cd windows/src-tauri
cargo test

# Shared Protocol & Infrastructure Tests
cd infrastructure/signaling
npm test

# Android Unit Tests
cd android
./gradlew testDebugUnitTest
```
