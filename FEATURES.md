# CLIPSYNC — COMPREHENSIVE FEATURE SPECIFICATION (`FEATURES.md`)

**Tagline:** Copy Anywhere. Paste Everywhere.  
**Project Status:** Active Architecture & Initial Release Construction  
**Current Target Window:** 05:00 – 06:00 AM IST, 2026-10-19  

---

## 1. Project Overview

ClipSync is a cross-platform, accountless, zero-cloud-dependent clipboard synchronization and file-transfer application connecting Android mobile devices and Windows desktop systems. It is engineered with a strict device-centric trust model, smart hybrid networking (seamlessly switching between local network discovery, remote peer-to-peer WebRTC, and end-to-end encrypted relay fallback), bidirectional loop-prevented clipboard mirroring, local SQLite clipboard history with privacy filtering, and a strict solid-color, zero-gradient user interface.

### Core Architecture Pillars
1. **Accountless Device-Centric Trust:** No email, password, or third-party OAuth account. Cryptographic asymmetric keypairs (Ed25519 for signing, X25519 for key exchange) identify each installation.
2. **End-to-End Security:** All payload contents (clipboard text, URLs, images, and file chunks) are encrypted on the sending device and decrypted only on authenticated paired devices using ChaCha20-Poly1305 / AES-256-GCM. Relays and signaling servers have zero plaintext access.
3. **Smart Hybrid Connectivity:** Prioritizes local network direct sockets via mDNS/DNS-SD; seamlessly traverses NAT via WebRTC P2P; gracefully degrades to encrypted relay forwarding when direct paths fail.
4. **Resilient Synchronization Engine:** Monotonic logical timestamps, cryptographic content hashing, and origin device tracking eliminate ping-pong synchronization loops and resolve simultaneous modification conflicts deterministically.
5. **Privacy First:** Configurable sensitive-data filters (passwords, credit cards, recovery phrases), zero logging of clipboard payloads, ephemeral pairing tokens, and single-click device revocation.

---

## 2. Feature Index and Status Summary

| Feature ID | Feature Name | Primary Platform | Current Status |
| :--- | :--- | :--- | :--- |
| **FEAT-001** | Cryptographic Device Identity & Keystore Management | Cross-Platform | **In Progress** |
| **FEAT-002** | Ephemeral QR Code & Auth-Code Device Pairing | Cross-Platform | **Planned** |
| **FEAT-003** | Paired Device Directory, Authorization & Instant Revocation | Cross-Platform | **Planned** |
| **FEAT-004** | Smart Hybrid Connection Orchestrator | Cross-Platform | **Planned** |
| **FEAT-005** | Local Discovery via mDNS / DNS-SD & UDP Broadcast Fallback | Cross-Platform | **Planned** |
| **FEAT-006** | Authenticated Direct Local Encrypted Socket Transport | Cross-Platform | **Planned** |
| **FEAT-007** | Secure WebSocket Signaling Service & Client Protocol | Infrastructure / Shared | **Planned** |
| **FEAT-008** | Remote WebRTC Peer-to-Peer NAT Traversal | Cross-Platform | **Planned** |
| **FEAT-009** | End-to-End Encrypted Relay Fallback Pipeline | Infrastructure / Shared | **Planned** |
| **FEAT-010** | Bidirectional Clipboard Synchronization Engine | Android & Windows | **Planned** |
| **FEAT-011** | Loop Prevention & Deterministic Conflict Resolution Matrix | Shared Protocol | **Planned** |
| **FEAT-012** | Plain Text & URL Sanitized Transmission Engine | Cross-Platform | **Planned** |
| **FEAT-013** | Image Clipboard Synchronization (PNG / JPEG / WebP) | Cross-Platform | **Planned** |
| **FEAT-014** | Chunked Stream File Transfer with Blake3 / SHA-256 Integrity | Cross-Platform | **Planned** |
| **FEAT-015** | Unsupported Format Detection & Graceful Diagnostic Notice | Cross-Platform | **Planned** |
| **FEAT-016** | Local Encrypted SQLite Clipboard History & Search | Cross-Platform | **Planned** |
| **FEAT-017** | Sensitive Content Masking & Secret Exclusion Heuristics | Cross-Platform | **Planned** |
| **FEAT-018** | Windows Desktop Tauri 2 Integration & System Tray | Windows (Rust / React) | **Planned** |
| **FEAT-019** | Android Foreground Service & Clipboard Listener Integration | Android (Kotlin / Compose) | **Planned** |
| **FEAT-020** | Solid-Color Zero-Gradient UI/UX Design System | Android & Windows | **Planned** |
| **FEAT-021** | Advanced Application Settings & Self-Hosted Configuration | Cross-Platform | **Planned** |
| **FEAT-022** | Connection Diagnostics & Real-time Peer Inspector | Cross-Platform | **Planned** |
| **FEAT-023** | System Error Handling, Backoff & Graceful Recovery | Cross-Platform | **Planned** |

---

## 3. Detailed Feature Specifications

### FEAT-001: Cryptographic Device Identity & Keystore Management
* **Feature ID:** `FEAT-001`
* **Purpose:** Establish a permanent, tamper-resistant cryptographic identity for every ClipSync installation without centralized registration.
* **User Experience:** Upon first launch, the application displays a unique human-readable device name (e.g., "Galaxy-S24-184F" or "Desktop-Work-9A2E") with its public fingerprint. No passwords, emails, or phone numbers required.
* **Functional Behavior:** Generates an Ed25519 keypair for digital signatures/identity verification and an X25519 keypair for Diffie-Hellman key exchange. Generates a 64-character hex device ID derived from the SHA-256 hash of the Ed25519 public key.
* **Implementation Requirements:**
  - *Android:* Android Keystore with `KeyGenParameterSpec` ensuring keys cannot be extracted in plaintext from hardware-backed storage.
  - *Windows:* Windows Credential Manager / DPAPI protected local encrypted key vault stored in the user app data directory.
* **Security & Privacy:** Private keys never leave the host device. Public keys are exchanged solely during mutual pairing ceremonies.
* **Failure Handling:** If hardware keystore is unavailable or corrupted, prompt the user with diagnostic details and offer a safe regeneration ritual that invalidates prior pairings.
* **Acceptance Criteria:** Key generation succeeds across clean installs; fingerprints match public key derivatives; private keys are inaccessible to unprivileged processes.
* **Testing:** Unit tests verifying signature generation, signature verification, and key serialization round-trips.
* **Status:** In Progress.

---

### FEAT-002: Ephemeral QR Code & Auth-Code Device Pairing
* **Feature ID:** `FEAT-002`
* **Purpose:** Enable mutual, authenticated, side-channel verification between an Android phone and a Windows desktop.
* **User Experience:** Windows desktop generates an on-screen QR code and a 6-digit confirmation code. Android scans the QR code using its camera, compares the 6-digit code, and both devices display an explicit "Approve Pairing" confirmation dialog with fingerprint verification.
* **Functional Behavior:**
  - Generates an ephemeral X25519 pairing session key and a cryptographic nonce.
  - Generates a payload containing: `{ device_id, device_name, public_key, session_token, local_ip_hints, port, expires_at }`.
  - Token validity is strictly clamped to 180 seconds (3 minutes).
  - Mutual approval signs the exchange with the respective Ed25519 identity keys.
* **Security & Privacy:** Mitigates Man-In-The-Middle (MITM) attacks via visual comparison of the 6-digit short authentication string (SAS). Expired tokens are rejected immediately.
* **Failure Handling:** Timeout triggers clean state reset with a fresh QR code generation button; mismatched SAS code aborts pairing.
* **Acceptance Criteria:** Pairing successfully records mutual public keys in local databases; expired codes cannot complete handshake.
* **Testing:** Automated tests for payload validation, expiration enforcement, and signature verification; manual testing with Android camera scanner.
* **Status:** Planned.

---

### FEAT-003: Paired Device Directory, Authorization & Instant Revocation
* **Feature ID:** `FEAT-003`
* **Purpose:** Allow users to inspect all authorized peers and instantly revoke any compromised or discarded device.
* **User Experience:** "Paired Devices" list displays device type icon, name, fingerprint, pairing date, last seen timestamp, and a prominent red "Revoke" button.
* **Functional Behavior:**
  - Persists peer metadata (device_id, name, ed25519_pubkey, x25519_pubkey, authorized_at, last_seen) in SQLite.
  - Revocation deletes peer credentials locally and broadcasts a signed `RevocationNotice` message across active transports.
  - Any future packets signed by a revoked key are dropped with a security log event.
* **Failure Handling:** Offline revoked devices are barred from reconnecting upon re-establishing network contact due to persistent local revocation list.
* **Acceptance Criteria:** Once revoked, incoming clipboard packets from that peer are discarded without decryption or clipboard modification.
* **Testing:** Integration test asserting packet rejection following revocation.
* **Status:** Planned.

---

### FEAT-004: Smart Hybrid Connection Orchestrator
* **Feature ID:** `FEAT-004`
* **Purpose:** Coordinate connection paths, dynamically choosing the lowest-latency, highest-bandwidth, zero-cloud transport available.
* **State Machine:** `Offline` -> `Discovering` -> `Connecting_Local` -> `Connected_Direct` <-> `Connecting_Remote_P2P` <-> `Connected_Relay` -> `Reconnecting` -> `Error`.
* **Functional Behavior:**
  - Simultaneously probes local network via mDNS and remote signaling server.
  - If local direct socket succeeds, routes data locally, bypassing WAN.
  - If local fails and remote is configured, initiates WebRTC ICE candidate gathering.
  - If direct P2P ICE fails (symmetric NAT), opens end-to-end encrypted channel through configured relay fallback.
* **Acceptance Criteria:** Seamless fallback without clipboard payload loss; connection status badge reflects actual verified state.
* **Status:** Planned.

---

### FEAT-005: Local Discovery via mDNS / DNS-SD & UDP Broadcast Fallback
* **Feature ID:** `FEAT-005`
* **Purpose:** Zero-configuration automatic discovery of paired devices on local Wi-Fi / Ethernet subnets.
* **Functional Behavior:**
  - Registers mDNS service `_clipsync._tcp.local` on ephemeral port.
  - TXT records publish `{ id: device_id_prefix, v: protocol_version }` (no sensitive keys).
  - Listens for peer advertisements and initiates direct TLS socket.
  - Implements fallback UDP broadcast discovery for subnets where multicast DNS is filtered by routers.
* **Security:** Discovered devices are never trusted implicitly; must complete Ed25519 challenge-response handshake before session authorization.
* **Status:** Planned.

---

### FEAT-006: Authenticated Direct Local Encrypted Socket Transport
* **Feature ID:** `FEAT-006`
* **Purpose:** High-speed, low-latency LAN transport for clipboard events and file transfers without WAN egress.
* **Functional Behavior:**
  - Direct TCP stream secured via mutual TLS (mTLS) with self-signed identity certificates pinned to the paired Ed25519 keys, or authenticated framing with ChaCha20-Poly1305.
  - Frame structure: `[Length: 4B][Type: 2B][Seq: 8B][AuthTag: 16B][EncryptedPayload: NB]`.
* **Acceptance Criteria:** Latency under 50ms on local Wi-Fi; zero plaintext transmitted over local wire.
* **Status:** Planned.

---

### FEAT-007: Secure WebSocket Signaling Service & Client Protocol
* **Feature ID:** `FEAT-007`
* **Purpose:** Facilitate exchange of SDP offers, answers, and ICE candidates for WebRTC P2P when peers are on disparate networks.
* **Functional Behavior:**
  - Lightweight Node.js / Rust standalone signaling service.
  - Clients authenticate with signed challenge to prevent unauthorized room occupation.
  - Relays only signaling envelopes; closes channel once P2P or relay data channel connects.
  - Zero clipboard data ever passes through signaling server.
* **Status:** Planned.

---

### FEAT-008: Remote WebRTC Peer-to-Peer NAT Traversal
* **Feature ID:** `FEAT-008`
* **Purpose:** Direct peer-to-peer data synchronization across the internet across NATs and firewalls.
* **Functional Behavior:**
  - Uses WebRTC DataChannels (`ordered: true, maxRetransmits: 5`).
  - Standard STUN servers (`stun.l.google.com:19302` or user-configured self-hosted STUN).
  - Payloads wrapped in application-level E2EE layer as defense-in-depth on top of DTLS-SRTP.
* **Status:** Planned.

---

### FEAT-009: End-to-End Encrypted Relay Fallback Pipeline
* **Feature ID:** `FEAT-009`
* **Purpose:** Guarantee connectivity when both peers reside behind strict/symmetric NATs where WebRTC direct connection is impossible.
* **Functional Behavior:**
  - Application-level encrypted relay forwarding packets strictly between authenticated pair sessions.
  - Zero-knowledge: Relay sees only opaque ciphertext headers `[RecipientDeviceID, Nonce, Ciphertext]`.
  - Ephemeral memory queue; no persistent disk storage of payloads on relay.
* **Status:** Planned.

---

### FEAT-010: Bidirectional Clipboard Synchronization Engine
* **Feature ID:** `FEAT-010`
* **Purpose:** Automatically detect clipboard changes on Android/Windows, package payload, transmit to paired peers, and paste into target clipboard.
* **Functional Behavior:**
  - Hooks Windows `AddClipboardFormatListener` / OS clipboard events.
  - Hooks Android `ClipboardManager.OnPrimaryClipChangedListener`.
  - Verifies change is novel (SHA-256 hash differs from local cache and last remote sync).
  - Packages event with UUID, origin device ID, timestamp, and content payload.
* **Status:** Planned.

---

### FEAT-011: Loop Prevention & Deterministic Conflict Resolution Matrix
* **Feature ID:** `FEAT-011`
* **Purpose:** Prevent infinite ping-pong echo loops and resolve concurrent clipboard updates across devices.
* **Loop Prevention Algorithm:**
  1. Origin device assigns unique monotonic `event_id = hash(origin_id + counter + content_hash)`.
  2. Receiving device marks `event_id` in LRU received cache (size 1024) before updating local clipboard.
  3. Destination OS clipboard listener triggers upon programmatic paste, detects matching `content_hash` / active suppression window (750ms), and suppresses retransmission.
* **Conflict Resolution Matrix:**
  - If two devices update clipboard concurrently within delta-t (< 1000ms):
    - Higher monotonic timestamp wins.
    - Tie-breaker: Lexicographical comparison of device IDs (`device_id_A > device_id_B`).
    - Losing clipboard content is automatically saved to local Clipboard History so user never loses data.
* **Status:** Planned.

---

### FEAT-012: Plain Text & URL Sanitized Transmission Engine
* **Feature ID:** `FEAT-012`
* **Purpose:** Safely synchronize Unicode text and web URLs up to 1 MB size without execution risks.
* **Functional Behavior:**
  - Preserves UTF-8 Unicode, linebreaks (`\r\n` / `\n` normalization option), and whitespace.
  - Validates URLs against malformed schemes; rejects `javascript:`, `data:`, `file:`, or shell-injection payloads.
  - URLs are tagged with mime-type `text/uri-list` but NEVER auto-opened in browser without explicit user click.
* **Status:** Planned.

---

### FEAT-013: Image Clipboard Synchronization (PNG / JPEG / WebP)
* **Feature ID:** `FEAT-013`
* **Purpose:** Synchronize screenshots and copied images directly between Android and Windows clipboard buffers.
* **Functional Behavior:**
  - Detects bitmap/DIB/PNG clipboard formats on Windows.
  - Detects `image/*` content URIs on Android.
  - Validates image dimensions and file size (default cap: 15 MB).
  - Encrypts and transmits image payload.
  - Target device decodes into native bitmap and places directly into active clipboard.
* **Status:** Planned.

---

### FEAT-014: Secure Chunked File Transfer Workflow with Integrity Verification
* **Feature ID:** `FEAT-014`
* **Purpose:** Transmit large files between devices with user consent, progress reporting, and cryptographic integrity verification.
* **Transfer Lifecycle:**
  1. `TransferOffer`: Sender sends `{ transfer_id, file_name, file_size, sha256_hash, mime_type }`.
  2. User Prompt: Receiver displays prompt with file name, size, sender name, and [Accept] / [Reject] buttons.
  3. `TransferInit`: Receiver allocates sanitized staging file in designated downloads directory.
  4. `ChunkStream`: 64 KB encrypted chunks streamed with chunk sequence numbers and progress updates.
  5. `TransferVerify`: Receiver re-computes SHA-256 over assembled file and verifies against offer hash.
  6. Atomic move from staging `.part` file to final destination.
* **Path Traversal Protection:** All filenames sanitized; absolute paths, `../`, and illegal OS characters stripped.
* **Status:** Planned.

---

### FEAT-015: Unsupported Format Detection & Graceful Diagnostic Notice
* **Feature ID:** `FEAT-015`
* **Purpose:** Prevent silent failures or crashes when unsupported clipboard formats (e.g., proprietary Office objects, rich audio) are copied.
* **Functional Behavior:** Logs format descriptor, displays a non-intrusive notification: *"Clipboard contained [Format], which is not yet supported for sync."*
* **Status:** Planned.

---

### FEAT-016: Local Encrypted SQLite Clipboard History & Search
* **Feature ID:** `FEAT-016`
* **Purpose:** Searchable local archive of past clipboard items with pinning and quick re-copying.
* **Functional Behavior:**
  - SQLite table: `id, content_type, text_content, blob_ref, timestamp, origin_device_id, is_pinned, is_sensitive`.
  - Full-text search over text items.
  - Copy-again places item back into active system clipboard.
  - Configurable retention: Keep last 25, 50, 100 items or clear after 24 hours.
  - Zero remote synchronization of history items; history remains strictly local.
* **Status:** Planned.

---

### FEAT-017: Sensitive Content Masking & Secret Exclusion Heuristics
* **Feature ID:** `FEAT-017`
* **Purpose:** Protect user credentials, API keys, and sensitive financial data from accidental synchronization.
* **Functional Behavior:**
  - Regex-based heuristics for credit card numbers (Luhn check), private keys (`-----BEGIN ...`), and password-manager clipboard flags (e.g., `ExcludeClipboardContentFromMonitorProcessing`).
  - Option to pause sync or prompt before synchronizing flagged secrets.
* **Status:** Planned.

---

### FEAT-018: Windows Desktop Tauri 2 Integration & System Tray
* **Feature ID:** `FEAT-018`
* **Purpose:** Lightweight, native Windows background desktop client with system tray controls.
* **Functional Behavior:**
  - Tauri 2 Rust backend managing low-level clipboard listeners, crypto, and SQLite.
  - System tray icon showing sync status (Connected, Syncing, Paused, Error).
  - Context menu: Show Window, Pause Sync, Clear History, Settings, Quit.
  - Auto-start with Windows configuration option.
* **Status:** Planned.

---

### FEAT-019: Android Foreground Service & Clipboard Listener Integration
* **Feature ID:** `FEAT-019`
* **Purpose:** Maintain reliable clipboard synchronization within modern Android background execution constraints.
* **Functional Behavior:**
  - Foreground Service with persistent status notification indicating sync readiness.
  - Quick Settings Tile / Notification action for "Sync Current Clipboard" and "Pause Sync".
  - Clean compliance with Android 10+ background clipboard restrictions (focus handling & foreground service).
* **Status:** Planned.

---

### FEAT-020: Solid-Color Zero-Gradient UI/UX Design System
* **Feature ID:** `FEAT-020`
* **Purpose:** Professional, high-contrast, distraction-free visual interface adhering strictly to the solid color requirement.
* **Design Specifications:**
  - **Zero Gradients Rule:** No linear, radial, or conic gradients on buttons, backgrounds, cards, or borders.
  - **Color Palette (Dark Theme):**
    - Background: `#121212`
    - Surface / Cards: `#1E1E1E`
    - Elevated Surface: `#2A2A2A`
    - Primary Accent: `#2563EB` (Solid Cobalt Blue)
    - Primary Hover: `#1D4ED8`
    - Text Primary: `#FFFFFF`
    - Text Secondary: `#A1A1AA`
    - Success: `#16A34A` (Solid Green)
    - Warning: `#CA8A04` (Solid Amber)
    - Error: `#DC2626` (Solid Red)
    - Border: `#333333`
* **Status:** Planned.

---

### FEAT-021: Advanced Application Settings & Self-Hosted Configuration
* **Feature ID:** `FEAT-021`
* **Purpose:** Give users total control over networking modes, self-hosted servers, retention, and permissions.
* **Configurable Keys:**
  - `network.mode`: `hybrid` | `local_only` | `remote_only`
  - `signaling.server_url`: Custom WebSocket endpoint (default: user self-hosted or local)
  - `relay.server_url`: Custom relay endpoint
  - `sync.auto_sync`: `true` | `false`
  - `sync.sync_images`: `true` | `false`
  - `sync.max_file_size_mb`: Numeric cap (default: 100 MB)
  - `history.enabled`: `true` | `false`
  - `history.retention_count`: `50`
* **Status:** Planned.

---

### FEAT-022: Connection Diagnostics & Real-time Peer Inspector
* **Feature ID:** `FEAT-022`
* **Purpose:** Provide complete transparency into active connection state, peer ping times, cipher suite, and packet statistics.
* **Functional Behavior:**
  - Real-time diagnostic panel displaying active transport mode (Direct LAN / P2P / Relay).
  - Round-trip latency meter.
  - Bytes sent / received counters.
  - Handshake verification status.
* **Status:** Planned.

---

### FEAT-023: System Error Handling, Backoff & Graceful Recovery
* **Feature ID:** `FEAT-023`
* **Purpose:** Ensure resilience against Wi-Fi drops, sleep/wake cycles, router resets, and socket drops.
* **Functional Behavior:**
  - Exponential backoff reconnect strategy: 1s, 2s, 4s, 8s, up to 30s max jittered delay.
  - Automatic re-establishment of sessions upon network interface change.
  - Preservation of clipboard state; no crash or unhandled panic.
* **Status:** Planned.

---

## 4. Phase 2 Roadmap (Future Expansion)
- iOS client using Network.framework and Action Extensions.
- macOS client with native menu bar item and Universal Clipboard coexistence.
- Linux client via Rust, GTK4 / Wayland & X11 clipboard integration.
- End-to-end encrypted multi-device group synchronizations (3+ devices).
