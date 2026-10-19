# 📱 ClipSync Cross-Platform Flutter Application

Unified cross-platform UI and client implementation for **Android** and **Windows** built with **Flutter 3.47+** and **Dart 3.13+**.

---

## 🎨 Design Philosophy & Principles

- **Zero-Gradients System:** Adheres strictly to ClipSync's solid-color, high-contrast, dark-mode design system.
  - Background: `#121212`
  - Surface: `#1E1E1E`
  - Elevated Cards: `#282828`
  - Accent: `#2563EB` (Cobalt Blue)
  - Security Badges: `#16A34A` (Green), `#CA8A04` (Amber), `#DC2626` (Red)
- **Adaptive Layout:**
  - **Desktop / Windows:** Left navigation rail sidebar with real-time status telemetry, multi-column dashboard, and high-density diagnostic views.
  - **Mobile / Android:** Sleek bottom navigation bar, touch-optimized card layouts, and responsive dialogs.

---

## 🚀 Features Implemented

1. **Dashboard:**
   - Real-time connection status badge (Direct LAN / WebRTC P2P / Encrypted Relay).
   - Metrics cards: Active peers, network latency (RTT), bytes transferred, security engine status.
   - Quick Manual Sync Bar: Type or paste clipboard text with one click to sign, encrypt, and broadcast.
   - Recent activity list with source tags and one-tap copy.
2. **Device Pairing:**
   - Ephemeral QR code generation with 180s countdown progress bar.
   - 6-digit Short Authentication String (SAS code) for visual verification against MITM attacks.
   - Manual auth-code input mode with label and confirmation.
3. **Authorized Devices Directory:**
   - Complete peer registry displaying device fingerprint, public key, pairing timestamp, and connection mode.
   - Instant Revoke action with safety dialog to invalidate compromised keys locally.
   - Blocked/revoked device history.
4. **Clipboard History & Vault:**
   - Live search filter by keyword or device.
   - Filter chips: All, Pinned, Sensitive.
   - Sensitive Content Masking: Automatic secret detection (SSH keys, tokens, passwords) with toggle reveal.
   - Individual item Pinning, Deleting, and one-tap Copy to system clipboard.
5. **Network Diagnostics & Peer Inspector:**
   - Smart Hybrid priority state visualizer (Direct Socket -> P2P WebRTC -> E2EE Relay).
   - Live packet event log stream with timestamp, event type, byte size, and E2EE verification tags.
   - Real-time telemetry inspector.
6. **Application Settings:**
   - Cryptographic Identity display (Node fingerprint, Ed25519 PubKey, X25519 PubKey).
   - Auto-sync clipboard toggle.
   - Secret exclusion filter heuristic toggle.
   - Local discovery port (TCP/UDP) & WebSocket signaling server URL configuration.

---

## 💻 How to Run

### Run on Windows / Web / Android Device
```powershell
# From the workspace root:
cd flutter_app

# Run on Chrome for quick interactive inspection:
flutter run -d chrome

# Run on Windows desktop:
flutter run -d windows

# Run on connected Android phone or emulator:
flutter run -d android
```

### Build Android APK
```powershell
cd flutter_app
flutter build apk --debug
```
