import React, { useState } from 'react';
import type { AppSettings } from '../types';
import { IconCheck } from './Icons';

interface SettingsTabProps {
  settings: AppSettings;
  onSaveSettings: (settings: AppSettings) => void;
  deviceName: string;
  onUpdateDeviceName: (name: string) => void;
}

export const SettingsTab: React.FC<SettingsTabProps> = ({
  settings: initialSettings,
  onSaveSettings,
  deviceName,
  onUpdateDeviceName,
}) => {
  const [settings, setSettings] = useState<AppSettings>(initialSettings);
  const [saved, setSaved] = useState(false);
  const [editingName, setEditingName] = useState(deviceName);
  const [nameSaved, setNameSaved] = useState(false);

  // Sync editingName when external deviceName changes
  React.useEffect(() => {
    setEditingName(deviceName);
  }, [deviceName]);

  const handleSaveName = () => {
    if (editingName.trim()) {
      onUpdateDeviceName(editingName.trim());
      setNameSaved(true);
      setTimeout(() => setNameSaved(false), 2500);
    }
  };

  const handleSave = () => {
    onSaveSettings(settings);
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  };

  return (
    <div style={{ padding: '28px', maxWidth: '860px', margin: '0 auto', width: '100%' }}>
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: '24px',
      }}>
        <div>
          <h1 style={{ fontSize: '20px', fontWeight: 600, letterSpacing: '-0.3px' }}>Settings</h1>
          <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginTop: '2px' }}>
            Configure device name, network discovery, self-hosted endpoints, and privacy controls
          </p>
        </div>
        <button className="primary" onClick={handleSave}>
          {saved ? <IconCheck size={14} color="#FFFFFF" /> : null}
          <span>{saved ? 'Saved!' : 'Save Changes'}</span>
        </button>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
        {/* Device & Display Name Card */}
        <div style={{
          backgroundColor: 'var(--bg-surface)',
          border: '1px solid var(--border-subtle)',
          borderRadius: 'var(--radius-md)',
          padding: '20px',
        }}>
          <h2 style={{ fontSize: '14px', fontWeight: 600, marginBottom: '6px' }}>Device & Username (Display Name)</h2>
          <p style={{ fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '14px' }}>
            This name identifies this PC to paired Android phones during synchronization and QR pairing.
          </p>

          <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
            <input
              type="text"
              value={editingName}
              onChange={(e) => setEditingName(e.target.value)}
              placeholder="e.g. My-Workstation"
              maxLength={32}
              style={{
                flex: 1,
                padding: '8px 12px',
                backgroundColor: 'var(--bg-primary)',
                border: '1px solid var(--border-subtle)',
                borderRadius: 'var(--radius-sm)',
                color: 'var(--text-primary)',
                fontSize: '13px',
              }}
            />
            <button
              className="secondary"
              onClick={handleSaveName}
              disabled={!editingName.trim() || editingName === deviceName}
              style={{ whiteSpace: 'nowrap' }}
            >
              {nameSaved ? 'Saved!' : 'Update Name'}
            </button>
          </div>
        </div>
        {/* Network Mode */}
        <div style={{
          backgroundColor: 'var(--bg-surface)',
          border: '1px solid var(--border-subtle)',
          borderRadius: 'var(--radius-md)',
          padding: '20px',
        }}>
          <h2 style={{ fontSize: '14px', fontWeight: 600, marginBottom: '6px' }}>Network Connection Mode</h2>
          <p style={{ fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '14px' }}>
            Choose how ClipSync routes clipboard updates between devices.
          </p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            <label style={{ display: 'flex', alignItems: 'center', gap: '10px', fontSize: '13px', cursor: 'pointer' }}>
              <input
                type="radio"
                name="networkMode"
                value="hybrid"
                checked={settings.networkMode === 'hybrid'}
                onChange={() => setSettings({ ...settings, networkMode: 'hybrid' })}
              />
              <div>
                <strong>Smart Hybrid (Recommended)</strong> — Direct LAN when on same Wi-Fi, WebRTC P2P / Relay when remote.
              </div>
            </label>

            <label style={{ display: 'flex', alignItems: 'center', gap: '10px', fontSize: '13px', cursor: 'pointer' }}>
              <input
                type="radio"
                name="networkMode"
                value="local_only"
                checked={settings.networkMode === 'local_only'}
                onChange={() => setSettings({ ...settings, networkMode: 'local_only' })}
              />
              <div>
                <strong>Local Network Only</strong> — Disable all WAN egress. Strict LAN direct sockets only.
              </div>
            </label>
          </div>
        </div>

        {/* Self-Hosted Server Configuration */}
        <div style={{
          backgroundColor: 'var(--bg-surface)',
          border: '1px solid var(--border-subtle)',
          borderRadius: 'var(--radius-md)',
          padding: '20px',
        }}>
          <h2 style={{ fontSize: '14px', fontWeight: 600, marginBottom: '6px' }}>Self-Hosted Infrastructure (Optional)</h2>
          <p style={{ fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '14px' }}>
            Point ClipSync to your private signaling and relay servers if not using local network sync.
          </p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            <div>
              <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '4px' }}>
                Signaling Server Endpoint (WebSocket)
              </label>
              <input
                type="text"
                value={settings.signalingUrl}
                onChange={(e) => setSettings({ ...settings, signalingUrl: e.target.value })}
                placeholder="wss://signaling.example.com or ws://127.0.0.1:8080"
                style={{ width: '100%' }}
              />
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '4px' }}>
                Encrypted Relay Server Endpoint (WebSocket)
              </label>
              <input
                type="text"
                value={settings.relayUrl}
                onChange={(e) => setSettings({ ...settings, relayUrl: e.target.value })}
                placeholder="wss://relay.example.com or ws://127.0.0.1:8081"
                style={{ width: '100%' }}
              />
            </div>
          </div>
        </div>

        {/* Synchronization & Privacy Controls */}
        <div style={{
          backgroundColor: 'var(--bg-surface)',
          border: '1px solid var(--border-subtle)',
          borderRadius: 'var(--radius-md)',
          padding: '20px',
        }}>
          <h2 style={{ fontSize: '14px', fontWeight: 600, marginBottom: '6px' }}>Privacy & Sync Behavior</h2>
          <p style={{ fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '14px' }}>
            Control automatic synchronization triggers and sensitive secret filters.
          </p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            <label style={{ display: 'flex', alignItems: 'center', gap: '10px', fontSize: '13px', cursor: 'pointer' }}>
              <input
                type="checkbox"
                checked={settings.autoSync}
                onChange={(e) => setSettings({ ...settings, autoSync: e.target.checked })}
              />
              <span>Automatically synchronize copied clipboard text without manual prompt</span>
            </label>

            <label style={{ display: 'flex', alignItems: 'center', gap: '10px', fontSize: '13px', cursor: 'pointer' }}>
              <input
                type="checkbox"
                checked={settings.syncImages}
                onChange={(e) => setSettings({ ...settings, syncImages: e.target.checked })}
              />
              <span>Synchronize screenshots and images (up to 15 MB)</span>
            </label>

            <label style={{ display: 'flex', alignItems: 'center', gap: '10px', fontSize: '13px', cursor: 'pointer' }}>
              <input
                type="checkbox"
                checked={settings.sensitiveFilterEnabled}
                onChange={(e) => setSettings({ ...settings, sensitiveFilterEnabled: e.target.checked })}
              />
              <span>Filter and mask recognized sensitive secrets (private keys, passwords, credit cards)</span>
            </label>
          </div>
        </div>
      </div>
    </div>
  );
};
