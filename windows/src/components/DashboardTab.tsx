import React, { useState } from 'react';
import type { ConnectionStatus, HistoryItem, PairedDevice } from '../types';
import { IconClipboard, IconCopy, IconCheck, IconAlert } from './Icons';

interface DashboardTabProps {
  status: ConnectionStatus;
  history: HistoryItem[];
  peers: PairedDevice[];
  onAddClipboard: (text: string) => void;
  onCopyItem: (text: string) => void;
  onClearHistory: () => void;
}

export const DashboardTab: React.FC<DashboardTabProps> = ({
  status,
  history,
  peers,
  onAddClipboard,
  onCopyItem,
}) => {
  const [inputText, setInputText] = useState('');
  const [copiedId, setCopiedId] = useState<string | null>(null);
  const [syncPaused, setSyncPaused] = useState(false);

  const handleSend = () => {
    if (!inputText.trim()) return;
    onAddClipboard(inputText.trim());
    setInputText('');
  };

  const handleCopy = (id: string, text: string) => {
    onCopyItem(text);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 2000);
  };

  const latestItem = history[0];

  return (
    <div style={{ padding: '28px', maxWidth: '860px', margin: '0 auto', width: '100%' }}>
      {/* Top Banner & Status Controls */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: '24px',
      }}>
        <div>
          <h1 style={{ fontSize: '20px', fontWeight: 600, letterSpacing: '-0.3px' }}>Dashboard</h1>
          <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginTop: '2px' }}>
            Bidirectional clipboard synchronization active across paired devices
          </p>
        </div>
        <div style={{ display: 'flex', gap: '8px' }}>
          <button
            onClick={() => setSyncPaused(!syncPaused)}
            className="secondary"
            style={{
              backgroundColor: syncPaused ? 'var(--status-warning)' : 'var(--bg-surface-elevated)',
              color: syncPaused ? '#000000' : 'var(--text-primary)',
            }}
          >
            {syncPaused ? 'Resume Synchronization' : 'Pause Synchronization'}
          </button>
        </div>
      </div>

      {/* Grid: Active Peer Cards & Connection Mode */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
        gap: '14px',
        marginBottom: '24px',
      }}>
        <div style={{
          backgroundColor: 'var(--bg-surface)',
          border: '1px solid var(--border-subtle)',
          borderRadius: 'var(--radius-md)',
          padding: '16px',
        }}>
          <div style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 500 }}>Active Transport</div>
          <div style={{ fontSize: '16px', fontWeight: 600, marginTop: '6px', color: 'var(--accent-primary)' }}>
            {status.transport_mode}
          </div>
          <div style={{ fontSize: '12px', color: 'var(--text-secondary)', marginTop: '4px' }}>
            Latency: {status.ping_ms}ms • Direct Socket
          </div>
        </div>

        <div style={{
          backgroundColor: 'var(--bg-surface)',
          border: '1px solid var(--border-subtle)',
          borderRadius: 'var(--radius-md)',
          padding: '16px',
        }}>
          <div style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 500 }}>Connected Devices</div>
          <div style={{ fontSize: '16px', fontWeight: 600, marginTop: '6px' }}>
            {peers.length} Authorized {peers.length === 1 ? 'Peer' : 'Peers'}
          </div>
          <div style={{ fontSize: '12px', color: 'var(--text-secondary)', marginTop: '4px' }}>
            {peers.filter(p => !p.is_revoked).length} active in sync ring
          </div>
        </div>

        <div style={{
          backgroundColor: 'var(--bg-surface)',
          border: '1px solid var(--border-subtle)',
          borderRadius: 'var(--radius-md)',
          padding: '16px',
        }}>
          <div style={{ fontSize: '12px', color: 'var(--text-muted)', fontWeight: 500 }}>Total Synchronized</div>
          <div style={{ fontSize: '16px', fontWeight: 600, marginTop: '6px' }}>
            {history.length} Clips
          </div>
          <div style={{ fontSize: '12px', color: 'var(--text-secondary)', marginTop: '4px' }}>
            Sent: {(status.bytes_sent / 1024).toFixed(1)} KB • Recv: {(status.bytes_received / 1024).toFixed(1)} KB
          </div>
        </div>
      </div>

      {/* Current Active Clipboard Section */}
      <div style={{
        backgroundColor: 'var(--bg-surface)',
        border: '1px solid var(--border-subtle)',
        borderRadius: 'var(--radius-md)',
        padding: '20px',
        marginBottom: '24px',
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <IconClipboard size={18} color="var(--accent-primary)" />
            <h2 style={{ fontSize: '14px', fontWeight: 600 }}>Active Clipboard Content</h2>
          </div>
          {latestItem && (
            <span style={{ fontSize: '11px', color: 'var(--text-muted)' }}>
              Updated {new Date(latestItem.timestamp).toLocaleTimeString()}
            </span>
          )}
        </div>

        {latestItem ? (
          <div>
            <div style={{
              backgroundColor: 'var(--bg-primary)',
              border: '1px solid var(--border-subtle)',
              borderRadius: 'var(--radius-sm)',
              padding: '12px 14px',
              fontSize: '13px',
              fontFamily: 'monospace',
              maxHeight: '140px',
              overflowY: 'auto',
              whiteSpace: 'pre-wrap',
              wordBreak: 'break-all',
              color: latestItem.is_sensitive ? 'var(--status-warning)' : 'var(--text-primary)',
            }}>
              {latestItem.text_data}
            </div>

            {latestItem.is_sensitive && (
              <div style={{
                marginTop: '10px',
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                padding: '8px 12px',
                backgroundColor: '#272008',
                border: '1px solid #78350F',
                borderRadius: 'var(--radius-sm)',
                fontSize: '12px',
                color: 'var(--status-warning)',
              }}>
                <IconAlert size={16} color="var(--status-warning)" />
                <span>Sensitive content detected (secret/key). Transmission is flagged for privacy.</span>
              </div>
            )}

            <div style={{ marginTop: '12px', display: 'flex', gap: '8px' }}>
              <button
                className="secondary"
                onClick={() => handleCopy(latestItem.id, latestItem.text_data)}
              >
                {copiedId === latestItem.id ? <IconCheck size={14} color="var(--status-success)" /> : <IconCopy size={14} />}
                <span>{copiedId === latestItem.id ? 'Copied to Clipboard' : 'Copy Again'}</span>
              </button>
            </div>
          </div>
        ) : (
          <div style={{ padding: '24px 0', textAlign: 'center', color: 'var(--text-muted)', fontSize: '13px' }}>
            No clipboard events recorded yet. Copy text or URLs to start synchronizing.
          </div>
        )}
      </div>

      {/* Manual Clipboard Sender / Broadcaster */}
      <div style={{
        backgroundColor: 'var(--bg-surface)',
        border: '1px solid var(--border-subtle)',
        borderRadius: 'var(--radius-md)',
        padding: '20px',
      }}>
        <h2 style={{ fontSize: '14px', fontWeight: 600, marginBottom: '10px' }}>
          Broadcast Text or URL to Paired Devices
        </h2>
        <div style={{ display: 'flex', gap: '10px' }}>
          <input
            type="text"
            placeholder="Type text or paste URL to send instantly..."
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSend()}
            style={{ flex: 1 }}
          />
          <button className="primary" onClick={handleSend}>
            Broadcast
          </button>
        </div>
      </div>
    </div>
  );
};
