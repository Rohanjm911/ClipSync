import React from 'react';
import {
  IconClipboard,
  IconQr,
  IconDevices,
  IconHistory,
  IconActivity,
  IconSettings,
} from './Icons';
import type { ConnectionStatus } from '../types';

export type TabType = 'dashboard' | 'pairing' | 'devices' | 'history' | 'diagnostics' | 'settings';

interface NavigationProps {
  currentTab: TabType;
  onTabChange: (tab: TabType) => void;
  status: ConnectionStatus;
  deviceName: string;
}

export const Navigation: React.FC<NavigationProps> = ({
  currentTab,
  onTabChange,
  status,
  deviceName,
}) => {
  const isConnected = status.state === 'CONNECTED_DIRECT' || status.state === 'CONNECTED_RELAY' || status.active_peer_count > 0;

  const getStatusDotColor = () => {
    if (isConnected) {
      return 'var(--status-success)';
    }
    switch (status.state) {
      case 'CONNECTED_RELAY':
        return 'var(--status-warning)';
      case 'ERROR':
      case 'OFFLINE':
        return 'var(--status-error)';
      default:
        return 'var(--status-warning)';
    }
  };

  const navItems: { id: TabType; label: string; icon: React.ReactNode }[] = [
    { id: 'dashboard', label: 'Dashboard', icon: <IconClipboard size={18} /> },
    { id: 'pairing', label: 'Pair Device', icon: <IconQr size={18} /> },
    { id: 'devices', label: 'Paired Devices', icon: <IconDevices size={18} /> },
    { id: 'history', label: 'Clipboard History', icon: <IconHistory size={18} /> },
    { id: 'diagnostics', label: 'Diagnostics', icon: <IconActivity size={18} /> },
    { id: 'settings', label: 'Settings', icon: <IconSettings size={18} /> },
  ];

  return (
    <aside style={{
      width: '240px',
      backgroundColor: 'var(--bg-surface)',
      borderRight: '1px solid var(--border-subtle)',
      display: 'flex',
      flexDirection: 'column',
      height: '100vh',
    }}>
      {/* Brand Header */}
      <div style={{
        padding: '20px 18px',
        borderBottom: '1px solid var(--border-subtle)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <img
            src="/logo.png"
            alt="ClipSync Logo"
            style={{
              width: '32px',
              height: '32px',
              borderRadius: 'var(--radius-sm)',
              objectFit: 'contain',
            }}
          />
          <div>
            <div style={{ fontSize: '15px', fontWeight: 600, letterSpacing: '-0.2px' }}>ClipSync</div>
            <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>Windows Desktop</div>
          </div>
        </div>

        {/* Device & Status Badge */}
        <div style={{
          marginTop: '14px',
          padding: '8px 10px',
          backgroundColor: 'var(--bg-primary)',
          borderRadius: 'var(--radius-sm)',
          border: '1px solid var(--border-subtle)',
        }}>
          <div style={{ fontSize: '12px', fontWeight: 500, color: 'var(--text-primary)' }}>
            {deviceName || 'Detecting...'}
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginTop: '4px' }}>
            <span style={{
              width: '8px',
              height: '8px',
              borderRadius: '50%',
              backgroundColor: getStatusDotColor(),
              display: 'inline-block',
            }} />
            <span style={{
              fontSize: '11px',
              fontWeight: isConnected ? 600 : 400,
              color: isConnected ? 'var(--status-success)' : 'var(--text-secondary)',
            }}>
              {isConnected
                ? `CONNECTED (${status.transport_mode === 'DISCOVERING' ? 'LOCAL_WIFI' : status.transport_mode})`
                : `${status.state} (${status.transport_mode})`}
            </span>
          </div>
        </div>
      </div>

      {/* Nav Buttons */}
      <nav style={{ padding: '12px 10px', display: 'flex', flexDirection: 'column', gap: '4px', flex: 1 }}>
        {navItems.map((item) => {
          const isActive = currentTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => onTabChange(item.id)}
              style={{
                width: '100%',
                justifyContent: 'flex-start',
                padding: '9px 12px',
                backgroundColor: isActive ? 'var(--bg-surface-elevated)' : 'transparent',
                color: isActive ? 'var(--text-primary)' : 'var(--text-secondary)',
                border: '1px solid',
                borderColor: isActive ? 'var(--border-strong)' : 'transparent',
                borderRadius: 'var(--radius-sm)',
              }}
            >
              <span style={{ color: isActive ? 'var(--accent-primary)' : 'var(--text-muted)' }}>
                {item.icon}
              </span>
              <span>{item.label}</span>
            </button>
          );
        })}
      </nav>

      {/* Footer Info */}
      <div style={{
        padding: '14px 18px',
        borderTop: '1px solid var(--border-subtle)',
        fontSize: '11px',
        color: 'var(--text-muted)',
      }}>
        <div>Version 0.1.0-alpha</div>
        <div style={{ marginTop: '2px' }}>Zero-Cloud • E2EE Protected</div>
      </div>
    </aside>
  );
};
