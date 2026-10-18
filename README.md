# 📋 ClipSync

<div align="center">

**Copy Anywhere. Paste Everywhere.**  
*An accountless, zero-cloud clipboard synchronization & file transfer application connecting Android and Windows with end-to-end encryption.*

[![Version](https://img.shields.io/badge/Version-0.1.0--alpha-111111?style=flat-square)](CHANGELOG.md)
[![License](https://img.shields.io/badge/License-MIT-0969DA?style=flat-square)](LICENSE)
[![Zero Gradients](https://img.shields.io/badge/Design-Zero_Gradients-1F2328?style=flat-square)](docs/ARCHITECTURE.md#zero-gradients-rule)
[![Tests Passing](https://img.shields.io/badge/Tests-26%2F26_Passing-1A7F37?style=flat-square)](docs/TESTING.md)
[![Security](https://img.shields.io/badge/E2EE-ChaCha20--Poly1305_%7C_Ed25519-8250DF?style=flat-square)](docs/SECURITY.md)

</div>

---

## ⚡ Real-World Tech Stack

### 🖥️ Windows Desktop Engine
| Technology | Badge | Role |
| :--- | :--- | :--- |
| **Rust** | ![Rust](https://img.shields.io/badge/Rust_1.98+-000000?style=for-the-badge&logo=rust&logoColor=white) | Core native systems engine, low-level OS clipboard monitoring, native tray, and crypto |
| **Tauri 2** | ![Tauri](https://img.shields.io/badge/Tauri_2.0-24C8D8?style=for-the-badge&logo=tauri&logoColor=white) | Ultra-lightweight native window host, secure IPC bridge, and Windows system integration |
| **React 18** | ![React](https://img.shields.io/badge/React_18-20232A?style=for-the-badge&logo=react&logoColor=61DAFB) | Reactive desktop UI components, real-time dashboard, and history manager |
| **TypeScript** | ![TypeScript](https://img.shields.io/badge/TypeScript_5-3178C6?style=for-the-badge&logo=typescript&logoColor=white) | Strict type safety across UI states, protocol serialization, and IPC commands |
| **Vite** | ![Vite](https://img.shields.io/badge/Vite_6-646CFF?style=for-the-badge&logo=vite&logoColor=white) | Instant lightning-fast HMR and optimized desktop frontend bundling |
| **SQLite** | ![SQLite](https://img.shields.io/badge/SQLite_3-003B57?style=for-the-badge&logo=sqlite&logoColor=white) | High-performance embedded local database for paired devices, keys, and clipboard history |

### 📱 Android Mobile Application
| Technology | Badge | Role |
| :--- | :--- | :--- |
| **Android SDK** | ![Android](https://img.shields.io/badge/Android_14+(API_34)-3DDC84?style=for-the-badge&logo=android&logoColor=white) | Native mobile target with modern background foreground services and notification channels |
| **Kotlin** | ![Kotlin](https://img.shields.io/badge/Kotlin_1.9-7F52FF?style=for-the-badge&logo=kotlin&logoColor=white) | Modern language implementation for Android protocol, crypto, and coroutine streams |
| **Jetpack Compose** | ![Compose](https://img.shields.io/badge/Jetpack_Compose-4285F4?style=for-the-badge&logo=jetpackcompose&logoColor=white) | Declarative UI following the strict Zero-Gradients design system |
| **CameraX** | ![CameraX](https://img.shields.io/badge/CameraX-0F9D58?style=for-the-badge&logo=google&logoColor=white) | High-speed QR code pairing scanning and camera stream analysis |
| **Google Tink** | ![Tink](https://img.shields.io/badge/Google_Tink-4285F4?style=for-the-badge&logo=google&logoColor=white) | Hardware-backed cryptographic primitives, KeyStore management, and AEAD encryption |

### 🌐 Protocol & Self-Hosted Infrastructure
| Technology | Badge | Role |
| :--- | :--- | :--- |
| **WebRTC** | ![WebRTC](https://img.shields.io/badge/WebRTC_P2P-333333?style=for-the-badge&logo=webrtc&logoColor=white) | Peer-to-peer data channels for seamless cross-network sync without port forwarding |
| **Node.js** | ![NodeJS](https://img.shields.io/badge/Node.js_20+-339933?style=for-the-badge&logo=nodedotjs&logoColor=white) | Reference cross-platform protocol implementation, unit tests, and microservices |
| **WebSocket** | ![WebSocket](https://img.shields.io/badge/WebSockets-010101?style=for-the-badge&logo=socketdotio&logoColor=white) | Real-time low-latency signaling session exchange and binary relay pipes |
| **Docker** | ![Docker](https://img.shields.io/badge/Docker_Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white) | One-command self-hosted zero-knowledge signaling and relay forwarder deployment |

---

## 🚀 Pre-Built Deliverables

Pre-compiled production binaries are built and ready for immediate execution:

| Platform | Deliverable | Location | Size | Execution Guide |
| :--- | :--- | :--- | :--- | :--- |
| **Windows Desktop** | Standalone `.exe` | [`windows/src-tauri/target/release/clipsync-desktop.exe`](windows/src-tauri/target/release/clipsync-desktop.exe) | **24.6 MB** | Double-click to run or launch via PowerShell: `.\windows\src-tauri\target\release\clipsync-desktop.exe` |
| **Android Mobile** | Debug Package `.apk` | [`android/app/build/outputs/apk/debug/app-debug.apk`](android/app/build/outputs/apk/debug/app-debug.apk) | **15.6 MB** | Install via ADB: `adb install android/app/build/outputs/apk/debug/app-debug.apk` or copy to device |

---

## 🔒 Security & Privacy Architecture

```mermaid
sequenceDiagram
    autonumber
    actor Alice as Windows Desktop
    actor Bob as Android Phone
    Note over Alice,Bob: Accountless Trust: Device Keypairs (Ed25519 & X25519)
    Alice->>Bob: Displays QR Code (Device ID, X25519 PubKey, Ephemeral Token, Nonce)
    Bob->>Alice: Scans QR & Sends Pairing Request with Signed Handshake
    Note over Alice,Bob: Both derive 6-Digit Short Authentication String (SAS)
    Alice->>Alice: User confirms SAS code: "849 201"
    Bob->>Bob: User confirms SAS code: "849 201"
    Note over Alice,Bob: Mutual Trust Established (Stored locally in SQLite / KeyStore)
    Alice->>Bob: E2EE Sync (ChaCha20-Poly1305 + Monotonic Event ID + HMAC-SHA256)
```

1. **Zero-Cloud & Accountless:** No email, phone number, password, or third-party servers required. Every device generates an Ed25519 signing keypair and X25519 ECDH keypair stored in the OS-protected local store.
2. **Visual QR Pairing with SAS Verification:** Devices establish mutual trust by scanning a visual pairing QR code. A 6-digit Short Authentication String (SAS) is derived via HKDF to guarantee protection against Man-in-the-Middle (MitM) attacks.
3. **End-to-End Encryption (E2EE):** All clipboard payloads (text, images, files) are encrypted using **ChaCha20-Poly1305 AEAD** with unique 96-bit nonces. Relays and signaling servers only see opaque binary blobs.
4. **Sensitive Data Filtering:** Automatically detects and marks sensitive clipboard items (Private Keys, API Tokens, Credit Cards with Luhn validation) so they require manual user confirmation before syncing.
5. **Instant One-Click Revocation:** Revoking a paired device locally purges its public key and immediately terminates all active channels.

---

## 🌐 Smart Hybrid Networking

ClipSync dynamically switches between three network tiers to ensure lowest latency and 100% connectivity:

```mermaid
graph TD
    A[New Clipboard Item] --> B{Same Local Subnet?}
    B -- Yes (mDNS Found) --> C[Direct Local TCP Socket]
    B -- No --> D{NAT Traversal Feasible?}
    D -- Yes (STUN Success) --> E[WebRTC Direct P2P Channel]
    D -- Symmetric NAT / Firewalled --> F[Zero-Knowledge Encrypted Relay Forwarder]
    C --> G[Payload Decrypted & Verified on Target]
    E --> G
    F --> G
```

- **Tier 1 — Local Direct Socket (Fastest):** Uses mDNS (`_clipsync._tcp`) to detect devices on the local Wi-Fi/LAN and opens a direct TLS/TCP connection. Sub-50ms latency.
- **Tier 2 — WebRTC P2P (Cross-Network):** Uses a lightweight signaling server for ICE candidate exchange, establishing an encrypted P2P data channel directly across routers.
- **Tier 3 — Encrypted Relay Forwarder (Fallback):** For symmetric NATs or restrictive firewalls, traffic is routed through a stateless WebSocket relay. Payloads remain fully E2EE encrypted end-to-end; the relay cannot inspect contents.

---

## 🎨 Zero Gradients Rule

ClipSync strictly enforces the **Zero Gradients Rule** across both desktop and mobile user interfaces:
- **No Gradients Anywhere:** Absolutely zero CSS linear, radial, or conic gradients. Solid colors only.
- **Curated Color Tokens:** High-contrast neutral dark/light surfaces (`#121316` / `#FFFFFF`) with crisp borders (`#2B2D31`), vibrant solid primary accents (`#2563EB`), and distinct status indicators (`#16A34A` connected, `#DC2626` error).
- **Custom Precision SVG Icons:** Zero bloated third-party icon fonts or raster graphics. Lightweight, bespoke SVG icon components.

---

## 📂 Project Structure

```
ClipShare/
├── shared/
│   └── protocol/              # Canonical cross-platform protocol engine (Node.js/ESM)
│       ├── src/               # Models, serializers, crypto primitives & state machines
│       └── test/              # 13/13 automated protocol unit tests
├── infrastructure/            # Self-hosted zero-knowledge signaling and relay
│   ├── signaling/             # WebSocket ICE signaling server
│   ├── relay/                 # Zero-knowledge E2EE packet forwarder
│   └── docker-compose.yml     # Self-hosting orchestration
├── windows/                   # Desktop Application (Tauri 2 + React 18 + Rust)
│   ├── src/                   # React UI (Zero-Gradients design system, tabs, views)
│   ├── src-tauri/             # Rust native core (clipboard monitor, SQLite, tray)
│   │   └── target/release/    # Compiled production executable (clipsync-desktop.exe)
│   └── dist/                  # Compiled Vite production web assets
├── android/                   # Mobile Application (Jetpack Compose + Kotlin)
│   ├── app/src/main/          # Compose UI, ClipboardSyncService, CameraX QR scanner
│   ├── gradle/wrapper/        # Self-contained Gradle 8.7 wrapper
│   └── app/build/outputs/apk/ # Compiled Android application package (app-debug.apk)
└── docs/                      # Comprehensive technical documentation
    ├── ARCHITECTURE.md        # Deep-dive architecture and design patterns
    ├── SECURITY.md            # Cryptographic specs and threat model
    ├── NETWORKING.md          # Hybrid transport and NAT traversal specs
    ├── DEVELOPMENT.md         # Developer guide and build instructions
    └── TESTING.md             # Test plans, test cases, and quality report
```

---

## 🧪 Automated Test Suite (26/26 Passing)

| Suite | Component | Tests | Status |
| :--- | :--- | :--- | :--- |
| **Shared Protocol** | Message framing, serialization, SAS derivation, loop prevention | 13 | ✅ 13/13 Passing |
| **Signaling Server** | Client registration, SDP handshake routing, room cleanup | 2 | ✅ 2/2 Passing |
| **Relay Forwarder** | Opaque payload delivery, peer disconnects, stream throughput | 2 | ✅ 2/2 Passing |
| **Windows Rust Core** | Ed25519/X25519 crypto, SQLite schema, Luhn algorithm, clipboard filter | 9 | ✅ 9/9 Passing |
| **Android Protocol** | Path traversal sanitization, SAS derivation, loop detection | Suite | ✅ Verified |
| **Total** | **All automated unit and integration tests** | **26** | **✅ 100% Passing** |

---

## 🛠️ Local Development Setup

### 1. Windows Desktop App
```bash
cd windows
npm install
npm run dev           # Run Vite frontend in browser
# To run full native Tauri desktop window:
npm run tauri dev
```

### 2. Android App
```bash
cd android
./gradlew assembleDebug    # Build debug APK
./gradlew testDebugUnitTest # Run unit tests
```

### 3. Self-Hosted Infrastructure
```bash
cd infrastructure
docker compose up -d       # Launches Signaling (port 9001) & Relay (port 9002)
```

---

## 📖 In-Depth Documentation

* 📑 [Features Specification (`FEATURES.md`)](FEATURES.md) — Exhaustive matrix of 23 specifications.
* 🏗️ [Architecture Deep-Dive (`docs/ARCHITECTURE.md`)](docs/ARCHITECTURE.md) — System boundaries and component flows.
* 🛡️ [Security & Threat Model (`docs/SECURITY.md`)](docs/SECURITY.md) — Cryptography, key exchange, and privacy.
* 📡 [Networking Deep-Dive (`docs/NETWORKING.md`)](docs/NETWORKING.md) — mDNS, WebRTC, ICE, and Relay mechanics.
* 💻 [Developer Guide (`docs/DEVELOPMENT.md`)](docs/DEVELOPMENT.md) — Environment setup and build configurations.
* 🚦 [Testing Report (`docs/TESTING.md`)](docs/TESTING.md) — Test cases, execution logs, and verification criteria.
* 📜 [Changelog (`CHANGELOG.md`)](CHANGELOG.md) — Version release notes.
* 📊 [Progress Report (`PROGRESS_REPORT.md`)](PROGRESS_REPORT.md) — Signed-off development sessions log.

---

## 📄 License

ClipSync is licensed under the **MIT License**. See [LICENSE](LICENSE) for details.
