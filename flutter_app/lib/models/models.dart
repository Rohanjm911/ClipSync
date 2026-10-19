import 'package:flutter/material.dart';

class DeviceInfo {
  final String deviceId;
  final String deviceName;
  final String ed25519PubKey;
  final String x25519PubKey;
  final String platform;

  DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.ed25519PubKey,
    required this.x25519PubKey,
    required this.platform,
  });

  IconData get icon {
    final p = ('$platform $deviceName').toLowerCase();
    if (p.contains('pc') ||
        p.contains('windows') ||
        p.contains('desktop') ||
        p.contains('laptop') ||
        p.contains('mac') ||
        p.contains('linux') ||
        p.contains('workstation')) {
      return Icons.laptop;
    }
    return Icons.smartphone;
  }

  DeviceInfo copyWith({
    String? deviceId,
    String? deviceName,
    String? ed25519PubKey,
    String? x25519PubKey,
    String? platform,
  }) {
    return DeviceInfo(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      ed25519PubKey: ed25519PubKey ?? this.ed25519PubKey,
      x25519PubKey: x25519PubKey ?? this.x25519PubKey,
      platform: platform ?? this.platform,
    );
  }

  String get fingerprint =>
      deviceId.length > 16 ? deviceId.substring(0, 16) : deviceId;
}

class PairedDevice {
  final String deviceId;
  String deviceName;
  final String ed25519PubKey;
  final String x25519PubKey;
  final DateTime pairedAt;
  DateTime lastSeen;
  bool isRevoked;
  final String connectionType;
  final String platform;

  PairedDevice({
    required this.deviceId,
    required this.deviceName,
    required this.ed25519PubKey,
    required this.x25519PubKey,
    required this.pairedAt,
    required this.lastSeen,
    this.isRevoked = false,
    this.connectionType = 'Direct LAN',
    this.platform = 'Mobile (Android)',
  });

  IconData get icon {
    final p = ('$platform $deviceName').toLowerCase();
    if (p.contains('pc') ||
        p.contains('windows') ||
        p.contains('desktop') ||
        p.contains('laptop') ||
        p.contains('mac') ||
        p.contains('linux') ||
        p.contains('workstation')) {
      return Icons.laptop;
    }
    return Icons.smartphone;
  }

  String get fingerprint =>
      deviceId.length > 16 ? deviceId.substring(0, 16) : deviceId;
}

class HistoryItem {
  final String id;
  final String contentType;
  final String textData;
  final String contentHash;
  final String originDeviceId;
  final String originDeviceName;
  final DateTime timestamp;
  bool isPinned;
  bool isSensitive;

  HistoryItem({
    required this.id,
    required this.contentType,
    required this.textData,
    required this.contentHash,
    required this.originDeviceId,
    required this.originDeviceName,
    required this.timestamp,
    this.isPinned = false,
    this.isSensitive = false,
  });
}

enum ConnectionStateEnum {
  connectedDirect,
  connectedP2p,
  connectedRelay,
  discovering,
  offline,
  error,
}

class ConnectionStatus {
  final ConnectionStateEnum state;
  final String transportMode;
  final int activePeerCount;
  final int pingMs;
  final int bytesSent;
  final int bytesReceived;

  ConnectionStatus({
    required this.state,
    required this.transportMode,
    required this.activePeerCount,
    required this.pingMs,
    required this.bytesSent,
    required this.bytesReceived,
  });

  String get stateDisplay {
    switch (state) {
      case ConnectionStateEnum.connectedDirect:
        return 'Connected (Direct LAN)';
      case ConnectionStateEnum.connectedP2p:
        return 'Connected (WebRTC P2P)';
      case ConnectionStateEnum.connectedRelay:
        return 'Connected (E2EE Relay)';
      case ConnectionStateEnum.discovering:
        return 'Discovering Peers...';
      case ConnectionStateEnum.offline:
        return 'Offline';
      case ConnectionStateEnum.error:
        return 'Connection Error';
    }
  }
}

class PairingPayload {
  final String sessionId;
  final String deviceId;
  final String deviceName;
  final String ed25519PubKey;
  final String x25519PubKey;
  final String sasCode;
  final List<String> ipHints;
  final int port;
  final DateTime expiresAt;

  PairingPayload({
    required this.sessionId,
    required this.deviceId,
    required this.deviceName,
    required this.ed25519PubKey,
    required this.x25519PubKey,
    required this.sasCode,
    required this.ipHints,
    required this.port,
    required this.expiresAt,
  });

  String serialize() {
    return 'clipsync://pair?sid=$sessionId&dev=$deviceId&name=${Uri.encodeComponent(deviceName)}&ed=$ed25519PubKey&x=$x25519PubKey&sas=$sasCode&port=$port';
  }
}

class AppSettings {
  bool autoSync;
  bool excludeSensitive;
  bool notifyOnSync;
  int localPort;
  String signalingUrl;
  String companionIp;
  bool darkTheme;
  bool bluetoothEnabled;
  String transportMode;

  AppSettings({
    this.autoSync = true,
    this.excludeSensitive = true,
    this.notifyOnSync = true,
    this.localPort = 48901,
    this.signalingUrl = 'wss://signal.clipsync.local:8443',
    this.companionIp = '',
    this.darkTheme = true,
    this.bluetoothEnabled = true,
    this.transportMode = 'Auto (Wi-Fi + Bluetooth)',
  });
}

class DiagnosticEvent {
  final DateTime timestamp;
  final String eventType;
  final String details;
  final bool isEncrypted;
  final int sizeBytes;

  DiagnosticEvent({
    required this.timestamp,
    required this.eventType,
    required this.details,
    this.isEncrypted = true,
    this.sizeBytes = 0,
  });
}
