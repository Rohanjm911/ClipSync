import React, { useState } from 'react';
import type { PairedDevice } from '../types';
import { IconDevices, IconTrash, IconAlert, IconCheck } from './Icons';

interface DevicesTabProps {
  devices: PairedDevice[];
  onRevokeDevice: (deviceId: string) => Promise<void>;
}

export const DevicesTab: React.FC<DevicesTabProps> = ({ devices, onRevokeDevice }) => {
  const [revokingId, setRevokingId] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState('');
  const [errorMsg, setErrorMsg] = useState('');

  const handleRevoke = async (device: PairedDevice) => {
    if (!window.confirm(`Are you sure you want to revoke ${device.device_name}? This device will no longer be authorized to sync clipboard content.`)) {
      return;
    }

    try {
      setRevokingId(device.device_id);
      await onRevokeDevice(device.device_id);
      setSuccessMsg(`Device ${device.device_name} has been revoked.`);
      setTimeout(() => setSuccessMsg(''), 4000);
    } catch (err: any) {
      setErrorMsg('Failed to revoke device: ' + err.toString());
    } finally {
      setRevokingId(null);
    }
  };

  const activeDevices = devices.filter(d => !d.is_revoked);

  return (
    <div style={{ padding: '28px', maxWidth: '860px', margin: '0 auto', width: '100%' }}>
      <div style={{ marginBottom: '24px' }}>
        <h1 style={{ fontSize: '20px', fontWeight: 600, letterSpacing: '-0.3px' }}>Paired Devices</h1>
        <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginTop: '2px' }}>
          Manage authenticated devices authorized to receive and send clipboard events
        </p>
      </div>

      {successMsg && (
        <div style={{
          marginBottom: '20px',
          padding: '12px 16px',
          backgroundColor: '#0D3319',
          border: '1px solid var(--status-success)',
          borderRadius: 'var(--radius-md)',
          display: 'flex',
          alignItems: 'center',
          gap: '10px',
          color: '#4ADE80',
          fontSize: '13px',
        }}>
          <IconCheck size={18} color="var(--status-success)" />
          <span>{successMsg}</span>
        </div>
      )}

      {errorMsg && (
        <div style={{
          marginBottom: '20px',
          padding: '12px 16px',
          backgroundColor: '#381111',
          border: '1px solid var(--status-error)',
          borderRadius: 'var(--radius-md)',
          display: 'flex',
          alignItems: 'center',
          gap: '10px',
          color: '#F87171',
          fontSize: '13px',
        }}>
          <IconAlert size={18} color="var(--status-error)" />
          <span>{errorMsg}</span>
        </div>
      )}

      {activeDevices.length === 0 ? (
        <div style={{
          backgroundColor: 'var(--bg-surface)',
          border: '1px solid var(--border-subtle)',
          borderRadius: 'var(--radius-md)',
          padding: '40px 20px',
          textAlign: 'center',
        }}>
          <div style={{ display: 'flex', justifyContent: 'center', marginBottom: '12px' }}>
            <IconDevices size={32} color="var(--text-muted)" />
          </div>
          <h2 style={{ fontSize: '15px', fontWeight: 600, marginBottom: '6px' }}>No Paired Devices</h2>
          <p style={{ fontSize: '13px', color: 'var(--text-secondary)', maxWidth: '400px', margin: '0 auto 16px' }}>
            Pair your Android phone or another computer to enable seamless clipboard synchronization.
          </p>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {activeDevices.map((dev) => (
            <div
              key={dev.device_id}
              style={{
                backgroundColor: 'var(--bg-surface)',
                border: '1px solid var(--border-subtle)',
                borderRadius: 'var(--radius-md)',
                padding: '18px 20px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                <div style={{
                  width: '40px',
                  height: '40px',
                  backgroundColor: 'var(--bg-surface-elevated)',
                  borderRadius: 'var(--radius-sm)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  border: '1px solid var(--border-subtle)',
                }}>
                  <IconDevices size={20} color="var(--accent-primary)" />
                </div>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <span style={{ fontSize: '14px', fontWeight: 600 }}>{dev.device_name}</span>
                    <span style={{
                      padding: '2px 6px',
                      backgroundColor: 'var(--bg-primary)',
                      border: '1px solid var(--border-subtle)',
                      borderRadius: 'var(--radius-sm)',
                      fontSize: '10px',
                      color: 'var(--status-success)',
                    }}>
                      AUTHORIZED
                    </span>
                  </div>
                  <div style={{ fontSize: '11px', fontFamily: 'monospace', color: 'var(--text-muted)', marginTop: '4px' }}>
                    Fingerprint: {dev.device_id.substring(0, 16)}...
                  </div>
                  <div style={{ fontSize: '11px', color: 'var(--text-secondary)', marginTop: '2px' }}>
                    Paired on {new Date(dev.paired_at).toLocaleDateString()} • Last active {new Date(dev.last_seen).toLocaleTimeString()}
                  </div>
                </div>
              </div>

              <div>
                <button
                  className="danger"
                  disabled={revokingId === dev.device_id}
                  onClick={() => handleRevoke(dev)}
                >
                  <IconTrash size={14} />
                  <span>{revokingId === dev.device_id ? 'Revoking...' : 'Revoke Device'}</span>
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
