# ClipSync Development Guide (`DEVELOPMENT.md`)

## 1. Prerequisites and Toolchains

To build, run, and test ClipSync across Windows and Android, ensure the following tools are installed:

- **Node.js:** v18+ (verified with v24.11.1)
- **NPM / PNPM:** npm v10+ (verified with v11.5.2)
- **Rust:** 1.75+ (verified with rustc 1.98.1 x86_64-pc-windows-gnu)
- **C/C++ Compiler:** GCC/MinGW (WinLibs or LLVM-MinGW)
- **Java Development Kit (JDK):** JDK 17 (verified with OpenJDK 17.0.15 Temurin)
- **Android SDK:** Platforms 34 / 36, Build-Tools 34.0.0 / 36.0.0, Platform-Tools (adb)

---

## 2. Repository Structure

```
ClipSync/
├── FEATURES.md              # Complete specification and status
├── README.md                # Project landing guide
├── CHANGELOG.md             # Version history
├── PROGRESS_REPORT.md       # Incremental session logs
├── docs/                    # Architectural & security docs
├── shared/
│   └── protocol/            # Cross-platform message definitions & crypto schemas
├── windows/                 # Tauri 2 Windows desktop application
│   ├── src/                 # React 18 + TypeScript frontend
│   └── src-tauri/           # Rust backend & Win32 integration
├── android/                 # Kotlin Android Jetpack Compose app
│   ├── app/                 # Main Android application module
│   ├── build.gradle.kts     # Root build script
│   └── settings.gradle.kts  # Gradle settings
└── infrastructure/          # Self-hosted infrastructure
    ├── signaling/           # WebSocket signaling service
    └── relay/               # E2EE relay forwarder
```

---

## 3. Windows Application Setup (Tauri 2)

```bash
cd windows
npm install
npm run dev      # Launches Vite dev server with Tauri Rust backend
npm run build    # Produces production Windows desktop build
```

---

## 4. Android Application Setup

```bash
cd android
# Ensure ANDROID_HOME is set:
# $env:ANDROID_HOME = "C:\Users\<user>\AppData\Local\Android\Sdk"
./gradlew assembleDebug    # Builds debug APK
./gradlew test             # Runs unit tests
```

---

## 5. UI/UX Style Guidelines
- **Strict Zero-Gradients Rule:** All backgrounds, cards, buttons, badges, and modal dialogs must use solid colors.
- Use the defined color tokens from the design system (`#121212` background, `#1E1E1E` surface, `#2563EB` solid accent, `#16A34A` success, `#DC2626` error).
