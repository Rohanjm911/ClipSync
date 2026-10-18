import React, { useState } from 'react';
import type { HistoryItem } from '../types';
import { IconHistory, IconCopy, IconCheck, IconTrash, IconAlert } from './Icons';

interface HistoryTabProps {
  history: HistoryItem[];
  onCopyItem: (text: string) => void;
  onClearHistory: () => Promise<void>;
}

export const HistoryTab: React.FC<HistoryTabProps> = ({
  history,
  onCopyItem,
  onClearHistory,
}) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [filterType, setFilterType] = useState<'all' | 'text' | 'url' | 'sensitive'>('all');
  const [copiedId, setCopiedId] = useState<string | null>(null);

  const handleCopy = (id: string, text: string) => {
    onCopyItem(text);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 2000);
  };

  const filteredItems = history.filter((item) => {
    // Search query
    if (searchQuery && !item.text_data.toLowerCase().includes(searchQuery.toLowerCase())) {
      return false;
    }
    // Type filter
    if (filterType === 'url') return item.content_type === 'text/uri-list';
    if (filterType === 'sensitive') return item.is_sensitive;
    if (filterType === 'text') return item.content_type === 'text/plain' && !item.is_sensitive;
    return true;
  });

  return (
    <div style={{ padding: '28px', maxWidth: '860px', margin: '0 auto', width: '100%' }}>
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: '20px',
      }}>
        <div>
          <h1 style={{ fontSize: '20px', fontWeight: 600, letterSpacing: '-0.3px' }}>Clipboard History</h1>
          <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginTop: '2px' }}>
            Encrypted local archive with privacy exclusions and instant retrieval
          </p>
        </div>
        <div>
          <button className="secondary" onClick={onClearHistory}>
            <IconTrash size={14} />
            <span>Clear Unpinned</span>
          </button>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div style={{
        display: 'flex',
        gap: '12px',
        marginBottom: '20px',
      }}>
        <input
          type="text"
          placeholder="Search history items..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          style={{ flex: 1 }}
        />
        <select
          value={filterType}
          onChange={(e) => setFilterType(e.target.value as any)}
          style={{ width: '150px' }}
        >
          <option value="all">All Items</option>
          <option value="text">Plain Text</option>
          <option value="url">URLs</option>
          <option value="sensitive">Sensitive Items</option>
        </select>
      </div>

      {/* History Items List */}
      {filteredItems.length === 0 ? (
        <div style={{
          backgroundColor: 'var(--bg-surface)',
          border: '1px solid var(--border-subtle)',
          borderRadius: 'var(--radius-md)',
          padding: '40px 20px',
          textAlign: 'center',
          color: 'var(--text-muted)',
          fontSize: '13px',
        }}>
          <div style={{ display: 'flex', justifyContent: 'center', marginBottom: '8px' }}>
            <IconHistory size={24} color="var(--text-muted)" />
          </div>
          No clipboard items found matching current filters.
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
          {filteredItems.map((item) => (
            <div
              key={item.id}
              style={{
                backgroundColor: 'var(--bg-surface)',
                border: '1px solid var(--border-subtle)',
                borderRadius: 'var(--radius-md)',
                padding: '14px 16px',
                display: 'flex',
                flexDirection: 'column',
                gap: '8px',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <span style={{
                    padding: '2px 6px',
                    backgroundColor: 'var(--bg-primary)',
                    border: '1px solid var(--border-subtle)',
                    borderRadius: 'var(--radius-sm)',
                    fontSize: '10px',
                    color: item.is_sensitive ? 'var(--status-warning)' : 'var(--accent-primary)',
                  }}>
                    {item.content_type}
                  </span>
                  {item.is_sensitive && (
                    <span style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '4px',
                      fontSize: '11px',
                      color: 'var(--status-warning)',
                    }}>
                      <IconAlert size={12} color="var(--status-warning)" />
                      Sensitive Content
                    </span>
                  )}
                </div>
                <span style={{ fontSize: '11px', color: 'var(--text-muted)' }}>
                  {new Date(item.timestamp).toLocaleString()}
                </span>
              </div>

              <div style={{
                fontFamily: 'monospace',
                fontSize: '13px',
                color: item.is_sensitive ? 'var(--status-warning)' : 'var(--text-primary)',
                maxHeight: '80px',
                overflowY: 'hidden',
                whiteSpace: 'pre-wrap',
                wordBreak: 'break-all',
              }}>
                {item.text_data}
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '4px' }}>
                <button
                  className="secondary"
                  onClick={() => handleCopy(item.id, item.text_data)}
                  style={{ padding: '5px 10px', fontSize: '12px' }}
                >
                  {copiedId === item.id ? <IconCheck size={12} color="var(--status-success)" /> : <IconCopy size={12} />}
                  <span>{copiedId === item.id ? 'Copied' : 'Copy'}</span>
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
