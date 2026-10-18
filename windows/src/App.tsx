import { useState, useEffect } from 'react';
import { Navigation } from './components/Navigation';
import type { TabType } from './components/Navigation';
import { DashboardTab } from './components/DashboardTab';
import { PairingTab } from './components/PairingTab';
import { DevicesTab } from './components/DevicesTab';
import { HistoryTab } from './components/HistoryTab';
import { DiagnosticsTab } from './components/DiagnosticsTab';
import { SettingsTab } from './components/SettingsTab';
import type {
  DeviceInfo,
  PairedDevice,
  HistoryItem,
  ConnectionStatus,
  AppSettings,
  PairingPayload,
} from './types';

// Safe Tauri Invoke with Browser Mock Fallback
const isTauri = typeof window !== 'undefined' && '__TAURI_INTERNALS__' in window;

async function tauriInvoke<T>(cmd: string, args: Record<string, any> = {}): Promise<T> {
  if (isTauri) {
    try {
      // Dynamic import to avoid build errors if not in tauri runtime
      const { invoke } = await import('@tauri-apps/api/core');
      return await invoke<T>(cmd, args);
    } catch (e) {
      console.warn(`[Tauri] Invoke failed for ${cmd}, falling back to local state`, e);
    }
  }

  // Standalone dev mock fallback
  switch (cmd) {
    case 'get_device_identity':
      return {
        device_id: 'a9b4c810d7e523f1',
        device_name: 'Desktop-Win-A9B4',
        ed25519_pubkey: 'ed_pub_mock_key_001',
        x25519_pubkey: 'x_pub_mock_key_001',
      } as unknown as T;

    case 'get_connection_status':
      return {
        state: 'CONNECTED_DIRECT',
        transport_mode: 'LOCAL_WIFI',
        active_peer_count: 1,
        ping_ms: 14,
        bytes_sent: 5120,
        bytes_received: 9240,
      } as unknown as T;

    case 'generate_pairing_qr':
      return {
        session_id: 'sess_' + Math.random().toString(36).substring(2, 10),
        device_id: 'a9b4c810d7e523f1',
        device_name: 'Desktop-Win-A9B4',
        ed25519_pubkey: 'ed_pub_mock_key_001',
        x25519_pubkey: 'x_pub_mock_key_001',
        sas_code: '482910',
        ip_hints: ['192.168.1.105'],
        port: 48901,
        expires_at: Date.now() + 180000,
      } as unknown as T;

    case 'get_paired_devices':
      return [
        {
          device_id: 'phone_pixel_8_pro',
          device_name: 'Pixel 8 Pro (Mobile)',
          ed25519_pubkey: 'ed_phone_pub_123',
          x25519_pubkey: 'x_phone_pub_456',
          paired_at: Date.now() - 3600000,
          last_seen: Date.now() - 30000,
          is_revoked: false,
        },
      ] as unknown as T;

    case 'get_clipboard_history':
      return [
        {
          id: 'clip_1',
          content_type: 'text/plain',
          text_data: 'https://github.com/clipsync/clipsync',
          content_hash: 'hash_123',
          origin_device_id: 'phone_pixel_8_pro',
          timestamp: Date.now() - 120000,
          is_pinned: false,
          is_sensitive: false,
        },
      ] as unknown as T;

    case 'add_local_history_item':
      return {
        id: 'clip_' + Date.now(),
        content_type: 'text/plain',
        text_data: args.text,
        content_hash: 'hash_' + Date.now(),
        origin_device_id: 'a9b4c810d7e523f1',
        timestamp: Date.now(),
        is_pinned: false,
        is_sensitive: false,
      } as unknown as T;

    default:
      return {} as T;
  }
}

export function App() {
  const [currentTab, setCurrentTab] = useState<TabType>('dashboard');
  const [deviceInfo, setDeviceInfo] = useState<DeviceInfo>({
    device_id: '',
    device_name: 'ClipSync Desktop',
    ed25519_pubkey: '',
    x25519_pubkey: '',
  });

  const [status, setStatus] = useState<ConnectionStatus>({
    state: 'DISCOVERING',
    transport_mode: 'INITIALIZING',
    active_peer_count: 0,
    ping_ms: 0,
    bytes_sent: 0,
    bytes_received: 0,
  });

  const [peers, setPeers] = useState<PairedDevice[]>([]);
  const [history, setHistory] = useState<HistoryItem[]>([]);
  const [settings, setSettings] = useState<AppSettings>({
    networkMode: 'hybrid',
    signalingUrl: 'ws://127.0.0.1:8080',
    relayUrl: 'ws://127.0.0.1:8081',
    autoSync: true,
    syncImages: true,
    maxFileSizeMb: 100,
    historyRetentionCount: 50,
    sensitiveFilterEnabled: true,
  });

  // Load initial data
  useEffect(() => {
    async function loadData() {
      try {
        const id = await tauriInvoke<DeviceInfo>('get_device_identity');
        setDeviceInfo(id);

        const st = await tauriInvoke<ConnectionStatus>('get_connection_status');
        setStatus(st);

        const devList = await tauriInvoke<PairedDevice[]>('get_paired_devices');
        setPeers(devList);

        const hist = await tauriInvoke<HistoryItem[]>('get_clipboard_history', { limit: 50 });
        setHistory(hist);
      } catch (err) {
        console.error('Failed to load initial desktop state:', err);
      }
    }
    loadData();

    // Poll status every 4 seconds
    const interval = setInterval(async () => {
      try {
        const st = await tauriInvoke<ConnectionStatus>('get_connection_status');
        setStatus(st);
      } catch (_) {}
    }, 4000);

    return () => clearInterval(interval);
  }, []);

  const handleAddClipboard = async (text: string) => {
    try {
      const newItem = await tauriInvoke<HistoryItem>('add_local_history_item', { text });
      setHistory((prev) => [newItem, ...prev]);
    } catch (err) {
      console.error('Failed to broadcast clipboard item:', err);
    }
  };

  const handleCopyItem = async (text: string) => {
    try {
      if (navigator.clipboard) {
        await navigator.clipboard.writeText(text);
      }
    } catch (err) {
      console.warn('Browser clipboard API failed:', err);
    }
  };

  const handleClearHistory = async () => {
    try {
      await tauriInvoke('clear_history');
      setHistory((prev) => prev.filter((i) => i.is_pinned));
    } catch (err) {
      console.error('Failed to clear history:', err);
    }
  };

  const handleGenerateQR = async (): Promise<PairingPayload> => {
    return await tauriInvoke<PairingPayload>('generate_pairing_qr');
  };

  const handleConfirmPairing = async (
    peerDeviceId: string,
    peerName: string,
    peerEd25519Pubkey: string,
    peerX25519Pubkey: string
  ) => {
    await tauriInvoke('confirm_pairing', {
      peerDeviceId,
      peerName,
      peerEd25519Pubkey,
      peerX25519Pubkey,
    });
    const updated = await tauriInvoke<PairedDevice[]>('get_paired_devices');
    setPeers(updated);
  };

  const handleRevokeDevice = async (deviceId: string) => {
    await tauriInvoke('revoke_device', { deviceId });
    setPeers((prev) => prev.filter((p) => p.device_id !== deviceId));
  };

  const handleUpdateDeviceName = async (newName: string) => {
    try {
      const updated = await tauriInvoke<string>('update_device_name', { newName });
      setDeviceInfo((prev) => ({ ...prev, device_name: updated }));
    } catch (err) {
      console.error('Failed to update device name:', err);
    }
  };

  return (
    <div style={{ display: 'flex', width: '100vw', height: '100vh', overflow: 'hidden' }}>
      <Navigation
        currentTab={currentTab}
        onTabChange={setCurrentTab}
        status={status}
        deviceName={deviceInfo.device_name}
      />

      <main style={{ flex: 1, height: '100vh', overflowY: 'auto', backgroundColor: 'var(--bg-primary)' }}>
        {currentTab === 'dashboard' && (
          <DashboardTab
            status={status}
            history={history}
            peers={peers}
            onAddClipboard={handleAddClipboard}
            onCopyItem={handleCopyItem}
            onClearHistory={handleClearHistory}
          />
        )}

        {currentTab === 'pairing' && (
          <PairingTab
            onGenerateQR={handleGenerateQR}
            onConfirmPairing={handleConfirmPairing}
          />
        )}

        {currentTab === 'devices' && (
          <DevicesTab
            devices={peers}
            onRevokeDevice={handleRevokeDevice}
          />
        )}

        {currentTab === 'history' && (
          <HistoryTab
            history={history}
            onCopyItem={handleCopyItem}
            onClearHistory={handleClearHistory}
          />
        )}

        {currentTab === 'diagnostics' && (
          <DiagnosticsTab
            status={status}
            deviceId={deviceInfo.device_id}
          />
        )}

        {currentTab === 'settings' && (
          <SettingsTab
            settings={settings}
            onSaveSettings={setSettings}
            deviceName={deviceInfo ? deviceInfo.device_name : 'Windows Desktop'}
            onUpdateDeviceName={handleUpdateDeviceName}
          />
        )}
      </main>
    </div>
  );
}

export default App;
