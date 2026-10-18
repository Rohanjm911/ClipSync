# ClipSync

**Tagline:** Copy Anywhere. Paste Everywhere.  
**Version:** 0.1.0-alpha  
**Platforms:** Android & Windows (Desktop)  

---

## Overview

ClipSync is an accountless, zero-cloud-dependent clipboard synchronization and file transfer tool connecting Android mobile devices and Windows desktop computers.

Built with security, speed, and privacy at its foundation, ClipSync does not require user accounts, emails, or passwords. Pairing is achieved via secure visual QR codes and short authentication strings (SAS). Synchronization leverages local network discovery first (mDNS/TLS), falling back to WebRTC peer-to-peer and end-to-end encrypted relay forwarding only when necessary.

---

## Key Features

- **Accountless Device Identity:** Cryptographic Ed25519 and X25519 identity keypairs per installation with hardware-backed protection.
- **Smart Hybrid Networking:** Instant local network direct streaming with automatic WebRTC P2P and encrypted relay fallback.
- **Bidirectional Clipboard Mirroring:** Copies on Android appear on Windows, and vice versa.
- **Loop Prevention & Conflict Resolution:** Eliminates re-transmission echoes and provides deterministic conflict resolution.
- **Supported Formats:** UTF-8 Text, URLs, Screenshots / Images, and chunked File Transfers with hash verification.
- **Local History & Privacy:** Local SQLite storage with search, pin, and sensitive data auto-masking.
- **Strict Minimalist UI:** Solid colors only, zero gradients, dark and light themes, native Windows system tray.

---

## Quick Start

### Windows Desktop
```bash
cd windows
npm install
npm run dev
```

### Android Application
```bash
cd android
./gradlew assembleDebug
```

### Self-Hosted Infrastructure (Optional)
```bash
cd infrastructure/signaling && node server.js
cd infrastructure/relay && node relay.js
```

---

## Documentation Links

- [Comprehensive Features & Status Specification (`FEATURES.md`)](FEATURES.md)
- [System Architecture (`docs/ARCHITECTURE.md`)](docs/ARCHITECTURE.md)
- [Security & Threat Model (`docs/SECURITY.md`)](docs/SECURITY.md)
- [Smart Hybrid Networking (`docs/NETWORKING.md`)](docs/NETWORKING.md)
- [Development Setup (`docs/DEVELOPMENT.md`)](docs/DEVELOPMENT.md)
- [Testing & Quality Assurance (`docs/TESTING.md`)](docs/TESTING.md)
- [Changelog (`CHANGELOG.md`)](CHANGELOG.md)
- [Progress Reports (`PROGRESS_REPORT.md`)](PROGRESS_REPORT.md)
