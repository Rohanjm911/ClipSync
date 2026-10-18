# ClipSync Security Architecture & Threat Model (`SECURITY.md`)

## 1. Security Principles

ClipSync is engineered with zero-trust network assumptions and an accountless, device-centric trust model:
1. **Zero Knowledge in Transit:** Clipboard content, images, and files must be encrypted end-to-end (E2EE). Neither local network eavesdroppers nor signaling/relay servers can read the plaintext.
2. **Cryptographic Identity:** Device authentication relies entirely on asymmetric cryptography (Ed25519 digital signatures and X25519 key agreements), not IP addresses, MAC addresses, or network boundaries.
3. **Hardware-Backed Protection:** Private keys are stored in platform-protected keystores (Android Keystore / Windows DPAPI).
4. **Explicit Pairing Authorization:** No device can join the sync group without mutual user confirmation via out-of-band visual validation (QR code + 6-digit confirmation code).
5. **Immediate Revocation:** Revoking a device removes its keys immediately, preventing any further synchronization.

---

## 2. Threat Model

| Threat | Risk Level | Mitigation in ClipSync |
| :--- | :--- | :--- |
| **Local Wi-Fi Eavesdropping** | High | All local TCP sockets use authenticated TLS 1.3 or ChaCha20-Poly1305 with peer-pinned public keys. |
| **Rogue Device on LAN** | High | mDNS discovery only discovers candidates; no data is accepted without prior mutual pairing and valid Ed25519 signatures. |
| **Compromised Signaling / Relay Server** | Critical | Servers only see encrypted envelopes and routing headers. They have no access to private keys or shared symmetric secrets. |
| **Man-in-the-Middle (MITM) During Pairing** | High | QR code transfers the public key directly over a visual channel; mutual 6-digit SAS verification confirms authenticity out-of-band. |
| **Replay Attacks** | Medium | Every packet includes a monotonic counter, millisecond timestamp, and unique UUID verified against an LRU replay cache. |
| **Malicious File Path Traversal** | Critical | File transfers sanitize filenames, stripping directory separators (`/`, `\`, `..`) and invalid Windows/Android filename characters. Files are placed in user-designated download directories with `.part` staging files. |
| **Clipboard Snooping via Diagnostic Logs** | High | Clipboard payloads and encryption keys are strictly omitted from logs at all log levels (`INFO`, `DEBUG`, `TRACE`). |

---

## 3. Cryptographic Primitives

- **Digital Signatures & Identity:** Ed25519 (Edwards-curve Digital Signature Algorithm).
- **Key Exchange:** X25519 (Elliptic Curve Diffie-Hellman over Curve25519).
- **Key Derivation:** HKDF-SHA256 (HMAC-based Extract-and-Expand Key Derivation Function) to derive 256-bit session keys from the shared secret with context info.
- **Symmetric Authenticated Encryption:** ChaCha20-Poly1305 (IETF variant) with 96-bit unique nonces per message.
- **Data Integrity:** SHA-256 for clipboard content and Blake3 / SHA-256 for chunked file verification.

---

## 4. Pairing Protocol Walkthrough

```
Device A (Windows)                             Device B (Android)
  |                                                    |
  |-- Generates Ephemeral Pairing Session ------------>|
  |   (Session ID, Ephemeral X25519 pubkey, Nonce)     |
  |   Renders QR Code on Screen                        |
  |                                                    |
  |                   [Camera Scans QR]                |
  |                                                    |
  |<-- Sends Pairing Request --------------------------|
  |   (Device B Ed25519 pubkey, Device B X25519 pubkey,|
  |    Signed with B's Ed25519 key)                    |
  |                                                    |
  |-- Computes Shared Secret & 6-Digit SAS ------------|
  |   Displays 6-Digit SAS on Screen                   |
  |                                                    |
  |-- User Verifies 6-Digit SAS on Both Devices -------|
  |                                                    |
  |-- Sends Pairing Accept --------------------------->|
  |   (Device A Ed25519 pubkey, Device A X25519 pubkey,|
  |    Signed with A's Ed25519 key)                    |
  |                                                    |
  |-- Mutual Storage in SQLite Peered Devices Table ---|
```

---

## 5. Sensitive Data Protection

ClipSync incorporates regex and entropy-based heuristics to identify and optionally suppress automatic sync for:
- Standard password manager formats (supporting `ExcludeClipboardContentFromMonitorProcessing` Win32 format).
- Private key headers (`BEGIN RSA PRIVATE KEY`, `BEGIN OPENSSH PRIVATE KEY`).
- Credit card numbers passing the Luhn algorithm.
- Cryptocurrency seed phrases and private keys.
