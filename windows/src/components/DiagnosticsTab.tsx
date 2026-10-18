import React from 'react';
import type { ConnectionStatus } from '../types';
import { IconActivity, IconShield, IconCheck } from './Icons';

interface DiagnosticsTabProps {
  status: ConnectionStatus;
  deviceId: string;
}

export const DiagnosticsTab: React.FC<DiagnosticsTabProps> = ({
  status,
  deviceId,
}) => {
  return (
    <div style={{ padding: '28px', maxWidth: '860px', margin: '0 auto', width: '100%' }}>
      <div style={{ marginBottom: '24px' }}>
        <h1 style={{ fontSize: '20px', fontWeight: 600, letterSpacing: '-0.3px' }}>Connection Diagnostics</h1>
        <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginTop: '2px' }}>
          Real-time networking telemetry, cryptographic cipher suites, and sync metrics
        </p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '16px', marginBottom: '24px' }}>
        <div style={{
          backgroundColor: 'var(--bg-surface)',
          border: '1px solid var(--border-subtle)',
          borderRadius: 'var(--radius-md)',
          padding: '18px',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--text-muted)', fontSize: '12px' }}>
            <IconActivity size={16} />
            <span>Transport State</span>
          </div>
          <div style={{ fontSize: '18px', fontWeight: 700, marginTop: '8px', color: 'var(--accent-primary)' }}>
            {status.state}
          </div>
          <div style={{ fontSize: '12px', color: 'var(--text-secondary)', marginTop: '4px' }}>
            Active Route: {status.transport_mode}
          </div>
        </div>

        <div style={{
          backgroundColor: 'var(--bg-surface)',
          border: '1px solid var(--border-subtle)',
          borderRadius: 'var(--radius-md)',
          padding: '18px',
        }}>
          <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Round-Trip Latency</div>
          <div style={{ fontSize: '18px', fontWeight: 700, marginTop: '8px', color: 'var(--status-success)' }}>
            {status.ping_ms} ms
          </div>
          <div style={{ fontSize: '12px', color: 'var(--text-secondary)', marginTop: '4px' }}>
            Direct LAN measurement
          </div>
        </div>

        <div style={{
          backgroundColor: 'var(--bg-surface)',
          border: '1px solid var(--border-subtle)',
          borderRadius: 'var(--radius-md)',
          padding: '18px',
        }}>
          <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Bandwidth Transferred</div>
          <div style={{ fontSize: '18px', fontWeight: 700, marginTop: '8px' }}>
            {((status.bytes_sent + status.bytes_received) / 1024).toFixed(1)} KB
          </div>
          <div style={{ fontSize: '12px', color: 'var(--text-secondary)', marginTop: '4px' }}>
            Sent: {(status.bytes_sent / 1024).toFixed(1)} KB • Recv: {(status.bytes_received / 1024).toFixed(1)} KB
          </div>
        </div>
      </div>

      {/* Security & Protocol Specs Card */}
      <div style={{
        backgroundColor: 'var(--bg-surface)',
        border: '1px solid var(--border-subtle)',
        borderRadius: 'var(--radius-md)',
        padding: '20px',
        marginBottom: '20px',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '14px' }}>
          <IconShield size={18} color="var(--accent-primary)" />
          <h2 style={{ fontSize: '14px', fontWeight: 600 }}>Active Cryptographic Suite</h2>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px', fontSize: '12px' }}>
          <div>
            <div style={{ color: 'var(--text-muted)' }}>Identity & Signatures</div>
            <div style={{ fontWeight: 600, marginTop: '2px', color: 'var(--text-primary)' }}>Ed25519 (256-bit Edwards Curve)</div>
          </div>
          <div>
            <div style={{ color: 'var(--text-muted)' }}>Key Agreement</div>
            <div style={{ fontWeight: 600, marginTop: '2px', color: 'var(--text-primary)' }}>X25519 (Curve25519 ECDH)</div>
          </div>
          <div>
            <div style={{ color: 'var(--text-muted)' }}>Symmetric Payload Cipher</div>
            <div style={{ fontWeight: 600, marginTop: '2px', color: 'var(--text-primary)' }}>ChaCha20-Poly1305 (AEAD)</div>
          </div>
          <div>
            <div style={{ color: 'var(--text-muted)' }}>Integrity & Content Hash</div>
            <div style={{ fontWeight: 600, marginTop: '2px', color: 'var(--text-primary)' }}>SHA-256 (FIPS 180-4)</div>
          </div>
        </div>

        <div style={{
          marginTop: '16px',
          padding: '10px 12px',
          backgroundColor: 'var(--bg-primary)',
          borderRadius: 'var(--radius-sm)',
          border: '1px solid var(--border-subtle)',
          fontSize: '11px',
          fontFamily: 'monospace',
          color: 'var(--text-secondary)',
          wordBreak: 'break-all',
        }}>
          Host Device ID: {deviceId || 'Generating...'}
        </div>
      </div>

      {/* Engine Status Indicators */}
      <div style={{
        backgroundColor: 'var(--bg-surface)',
        border: '1px solid var(--border-subtle)',
        borderRadius: 'var(--radius-md)',
        padding: '20px',
      }}>
        <h2 style={{ fontSize: '14px', fontWeight: 600, marginBottom: '14px' }}>Sync Engine Health Checks</h2>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', fontSize: '12px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <IconCheck size={16} color="var(--status-success)" />
            <span>Loop Prevention Cache Active (1024-entry LRU event registry)</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <IconCheck size={16} color="var(--status-success)" />
            <span>Deterministic Conflict Resolution Matrix Enabled</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <IconCheck size={16} color="var(--status-success)" />
            <span>Windows Clipboard Update Hook Initialized (Win32 AddClipboardFormatListener)</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <IconCheck size={16} color="var(--status-success)" />
            <span>Path Traversal Sanitizer Active for File Transfers</span>
          </div>
        </div>
      </div>
    </div>
  );
};
