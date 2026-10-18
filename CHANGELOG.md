# ClipSync Changelog (`CHANGELOG.md`)

All notable changes to the ClipSync project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Comprehensive feature specification in `FEATURES.md` spanning 23 detailed features with stable IDs (`FEAT-001` through `FEAT-023`).
- Project architecture documentation in `docs/ARCHITECTURE.md`.
- Security specification and zero-trust threat model in `docs/SECURITY.md`.
- Smart Hybrid networking specification (LAN mDNS, WebRTC P2P, E2EE relay) in `docs/NETWORKING.md`.
- Development and environment configuration guide in `docs/DEVELOPMENT.md`.
- Verification and testing plan in `docs/TESTING.md`.
- Project `README.md` and `.gitignore`.
- Shared Wire Protocol (`shared/protocol`) with JSON schema, path traversal sanitization, SAS code derivation, monotonic event IDs, and conflict resolution matrix. Tested with 13 automated unit tests.
- Standalone WebSocket Signaling Server (`infrastructure/signaling`) with client registration and WebRTC signal forwarder. Tested with automated integration tests.
- Standalone E2EE Relay Server (`infrastructure/relay`) with zero-knowledge envelope forwarding and stats endpoint. Tested with automated integration tests.
- Windows Desktop Tauri 2 Rust core (`windows/src-tauri`):
  - `crypto.rs`: Ed25519 identity keypairs, X25519 key agreement, ChaCha20-Poly1305 AEAD, and SHA-256 content hashing. Tested with unit tests.
  - `storage.rs`: SQLite database with tables for device identity, paired devices, local clipboard history, and key-value settings. Tested with lifecycle tests.
  - `protocol.rs`: Rust protocol definitions, loop prevention event IDs, and deterministic conflict resolution. Tested with unit tests.
  - `clipboard.rs`: Sensitive content filtering (private keys, Luhn credit cards, API tokens), URL detection, and sanitization. Tested with unit tests.
- Windows Desktop React 18 + TypeScript frontend (`windows/`):
  - Strict zero-gradient, solid-color dark design system in `index.css`.
  - Precision embedded SVG icon set (`Icons.tsx`).
  - Six functional tabs: Dashboard, QR Pairing & SAS verification, Paired Devices directory & revocation, Local History with search/filter, Diagnostics telemetry, and Advanced Settings.
  - Production frontend bundle successfully compiled into `windows/dist`.
- Android Jetpack Compose application (`android/app`):
  - Data models (`model/Models.kt`), `ProtocolEngine.kt` with path traversal sanitization, SAS derivation, and sensitive content detection.
  - `ClipboardSyncService.kt` foreground service with notification channel, suppression window, and broadcast.
  - Strict zero-gradient `Theme.kt` and complete `MainActivity.kt` with Compose tabs.
  - Automated unit tests in `ProtocolEngineTest.kt`.
