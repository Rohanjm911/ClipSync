# ClipSync System Architecture (`ARCHITECTURE.md`)

## 1. High-Level Architecture Overview

ClipSync is built on an accountless, distributed, peer-to-peer and local-first architecture. There is no central database of users, passwords, or synchronized content. Each installation acts as an autonomous node with its own cryptographic identity, local storage, and protocol handlers.

```
+-------------------------------------------------------------+
|                     Android Application                     |
|  - Jetpack Compose UI (Strict solid colors, zero gradients) |
|  - Android Foreground Service + OnPrimaryClipChanged        |
|  - Android Keystore (Ed25519 / X25519)                      |
|  - Room / SQLite Local History                              |
+-------------------------------------------------------------+
                              |
                     Hybrid Network Layer
        (mDNS LAN Direct Socket / WebRTC P2P / E2EE Relay)
                              |
+-------------------------------------------------------------+
|                     Windows Application                     |
|  - Tauri 2 Native Wrapper + Windows System Tray             |
|  - React + TypeScript Frontend (Solid colors, zero gradients)|
|  - Rust Backend (Core Engine, Win32 Clipboard API)          |
|  - SQLite Local History + DPAPI Key Vault                   |
+-------------------------------------------------------------+
```

---

## 2. Component Breakdown

### 2.1 Shared Protocol (`shared/protocol`)
The shared protocol defines the wire format and state machine for all nodes:
- **Wire Serialization:** Standardized JSON protocol framing or binary Protocol Buffers with header fields:
  - `version`: Protocol version integer (`1`).
  - `type`: Message type (`PairingRequest`, `PairingAccept`, `ClipboardSync`, `FileOffer`, `FileChunk`, `Revocation`).
  - `sender_id`: SHA-256 fingerprint of the sender's Ed25519 identity key.
  - `recipient_id`: Target device fingerprint.
  - `timestamp`: Monotonic millisecond Unix timestamp.
  - `signature`: Ed25519 digital signature computed over the serialized payload envelope.
  - `payload`: Authenticated ciphertext encrypted with ChaCha20-Poly1305 or AES-256-GCM.

### 2.2 Windows Desktop Client (`windows/`)
- **Tauri 2 Framework:** Provides a secure sandbox separating the React/TypeScript UI from the native OS capabilities.
- **Rust Core:**
  - `clipboard_listener`: Uses Windows Win32 API (`AddClipboardFormatListener`, `WM_CLIPBOARDUPDATE`) for low-overhead, event-driven notification of clipboard changes.
  - `crypto`: Rust `ed25519-dalek`, `x25519-dalek`, and `chacha20poly1305` crates for cryptographic operations.
  - `network`: Tokio-based async networking handling local TCP listeners, mDNS browsing, and WebSocket connections to signaling/relay servers.
  - `storage`: SQLite integration via `rusqlite` for local clipboard history and paired device registry.
  - `tray`: Windows system tray icon and menu controls.

### 2.3 Android Mobile Client (`android/`)
- **Language & UI:** Kotlin with Jetpack Compose.
- **Background Handling:** A dedicated Android `ForegroundService` with notification priority ensures the connection and clipboard listeners remain active without being killed by OS battery optimization.
- **Keystore Integration:** Hardware-backed key generation via `KeyGenParameterSpec` ensuring private keys cannot be dumped even from a rooted device.
- **Local Database:** Room persistence library for paired peers and local clipboard history.

### 2.4 Infrastructure Services (`infrastructure/`)
- **Signaling Server (`infrastructure/signaling`):** Lightweight Node.js / Rust WebSocket server that acts as a matchmaker. Peered devices connect, present signed authentication tokens, and exchange WebRTC SDP offers/answers. It never stores or inspects clipboard data.
- **Relay Server (`infrastructure/relay`):** Low-latency packet forwarder for peers where direct LAN or WebRTC P2P is blocked by carrier-grade symmetric NATs. Operates strictly on opaque, end-to-end encrypted envelopes.

---

## 3. Data Flow

### 3.1 Clipboard Synchronization Flow
1. **Change Detection:** User copies text on Android. Android `ClipboardManager.OnPrimaryClipChangedListener` fires.
2. **Hash & Loop Check:** Engine computes SHA-256 of clipboard data. If it matches the last received remote payload or current local cache, transmission is aborted.
3. **Payload Construction:** Engine creates a `ClipboardPayload` containing `content_type`, `data`, `origin_device_id`, `event_id`, and `timestamp`.
4. **Encryption:** Payload is encrypted with the pairwise shared symmetric secret (derived via X25519 Diffie-Hellman + HKDF).
5. **Envelope Signing:** Envelope is signed with sender's Ed25519 private key.
6. **Transport Routing:** Smart Hybrid Router chooses active transport:
   - If direct LAN connection is active -> send over direct TLS/TCP socket.
   - Else if WebRTC DataChannel is active -> send over P2P DataChannel.
   - Else -> send through configured E2EE relay.
7. **Reception & Decryption:** Windows Rust backend receives frame, verifies Ed25519 signature against stored peer public key, decrypts ciphertext with pairwise key, and checks `event_id` in LRU cache.
8. **Target Clipboard Injection:** Windows backend temporarily sets an internal `suppress_next_change` flag and injects the text into Win32 Clipboard. Flag resets after 750ms.
9. **History Logging:** Both devices record the item in their respective local SQLite history table (if history is enabled and content is not flagged sensitive).

---

## 4. Conflict Resolution Strategy
When simultaneous copies occur within a short time window ($\Delta t < 1000\text{ms}$):
1. The event with the higher timestamp takes precedence.
2. If timestamps are identical, the device with the lexicographically greater `device_id` wins.
3. The losing clipboard content is never discarded: it is saved into the recipient's local clipboard history with an indicator, allowing the user to retrieve it with one click.
