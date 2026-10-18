package com.clipsync.android.model

enum class ConnectionState {
    DISCOVERING,
    PAIRING,
    CONNECTING_LOCAL,
    CONNECTING_REMOTE,
    CONNECTED_DIRECT,
    CONNECTED_RELAY,
    RECONNECTING,
    OFFLINE,
    ERROR
}

data class DeviceIdentity(
    val deviceId: String,
    val deviceName: String,
    val ed25519PubKey: String,
    val x25519PubKey: String,
    val createdAt: Long
)

data class PairedDevice(
    val deviceId: String,
    val deviceName: String,
    val ed25519PubKey: String,
    val x25519PubKey: String,
    val pairedAt: Long,
    val lastSeen: Long,
    val isOnline: Boolean = false,
    val connectionMode: String = "LOCAL"
)

data class PairingPayload(
    val sessionId: String,
    val deviceId: String,
    val deviceName: String,
    val ed25519PubKey: String,
    val x25519PubKey: String,
    val sasCode: String,
    val ipHints: List<String>,
    val port: Int,
    val expiresAt: Long
)

data class ClipboardItem(
    val id: String,
    val contentType: String,
    val textData: String,
    val contentHash: String,
    val originDeviceId: String,
    val timestamp: Long,
    val isPinned: Boolean = false,
    val isSensitive: Boolean = false
)

data class FileOffer(
    val transferId: String,
    val originDeviceId: String,
    val fileName: String,
    val fileSize: Long,
    val sha256Hash: String,
    val mimeType: String
)
