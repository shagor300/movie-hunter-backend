import { useState, useEffect } from 'react';
import api from '../api';

export default function SourcesPage() {
    const [sources, setSources] = useState([]);
    const [isAddModalOpen, setIsAddModalOpen] = useState(false);
    const [newSourceName, setNewSourceName] = useState('');
    const [newSourceUrl, setNewSourceUrl] = useState('');
    const [addError, setAddError] = useState('');

    useEffect(() => {
        loadSources();
    }, []);

    const loadSources = () => {
        api.get('/admin/sources').then(r => setSources(r.data.sources || [])).catch(() => { });
    };

    const toggleSource = async (name, enabled) => {
        try {
            await api.put(`/admin/sources/${encodeURIComponent(name)}`, { enabled: !enabled });
            setSources(prev => prev.map(s => s.name === name ? { ...s, enabled: !s.enabled } : s));
        } catch { }
    };

    const syncSource = async (name) => {
        try { await api.post(`/admin/sources/${encodeURIComponent(name)}/sync`); } catch { }
    };

    const handleAddSource = async () => {
        setAddError('');
        if (!newSourceName || !newSourceUrl) {
            setAddError('Source Name and Source URL are required');
            return;
        }

        try {
            // Check for valid URL
            new URL(newSourceUrl);
        } catch (_) {
            setAddError('Invalid URL');
            return;
        }

        try {
            await api.post('/admin/sources', { source_name: newSourceName, source_url: newSourceUrl });
            setIsAddModalOpen(false);
            setNewSourceName('');
            setNewSourceUrl('');
            loadSources();
        } catch (error) {
            setAddError(error.response?.data?.detail || 'Failed to add source');
        }
    };

    const sourceIcons = { 'HDHub4u': 'language', 'SkyMoviesHD': 'cloud', 'BollyFlix': 'theaters', 'MoviesFlix': 'local_movies' };

    return (
        <div className="page-scroll">
            <div className="page-header">
                <div className="page-header-text">
                    <div className="page-label">Infrastructure</div>
                    <h2>Source Management</h2>
                    <p>Monitor and configure content scrapers</p>
                </div>
                <button className="btn btn-primary" onClick={() => setIsAddModalOpen(true)}>
                    <span className="material-symbols-outlined">add</span>
                    Add Source
                </button>
            </div>

            <div className="grid-2">
                {sources.map((source) => {
                    const statusClass = source.enabled ? (source.status === 'slow' ? 'slow' : 'online') : 'offline';
                    const statusLabel = source.enabled ? (source.status === 'slow' ? 'Degraded' : 'Online') : 'Offline';

                    return (
                        <div key={source.name} className="glass-card source-card">
                            <div className="source-card-header">
                                <div className="source-card-info">
                                    <div className="source-card-icon" style={{ background: source.enabled ? 'var(--primary-dim)' : 'var(--red-bg)' }}>
                                        <span className="material-symbols-outlined" style={{ color: source.enabled ? 'var(--primary)' : 'var(--red)' }}>
                                            {sourceIcons[source.name] || 'language'}
                                        </span>
                                    </div>
                                    <div>
                                        <div className="source-card-name">{source.name}</div>
                                        <div className="source-card-status">
                                            <div className={`dot ${statusClass}`}></div>
                                            <span style={{ color: statusClass === 'online' ? 'var(--green)' : statusClass === 'slow' ? 'var(--amber)' : 'var(--red)' }}>{statusLabel}</span>
                                        </div>
                                    </div>
                                </div>
                                <div className="source-card-controls">
                                    <button className="btn btn-sm" onClick={() => syncSource(source.name)}>
                                        <span className="material-symbols-outlined">sync</span>
                                        Sync
                                    </button>
                                    <label className="toggle">
                                        <input type="checkbox" checked={source.enabled} onChange={() => toggleSource(source.name, source.enabled)} />
                                        <span className="toggle-slider"></span>
                                    </label>
                                </div>
                            </div>

                            <div className="source-stats-grid">
                                <div className="source-stat">
                                    <div className="source-stat-label">Movies</div>
                                    <div className="source-stat-value">{(source.total_movies || 0).toLocaleString()}</div>
                                </div>
                                <div className="source-stat">
                                    <div className="source-stat-label">Success Rate</div>
                                    <div className="source-stat-value" style={{ color: 'var(--green)' }}>{source.success_rate || '—'}%</div>
                                </div>
                                <div className="source-stat">
                                    <div className="source-stat-label">Avg Response</div>
                                    <div className="source-stat-value">{source.avg_response || '—'}ms</div>
                                </div>
                            </div>

                            {source.last_sync && (
                                <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12, color: 'var(--text-muted)' }}>
                                    <span className="material-symbols-outlined" style={{ fontSize: 14 }}>schedule</span>
                                    Last sync: {source.last_sync}
                                </div>
                            )}
                        </div>
                    );
                })}
            </div>

            {sources.length === 0 && (
                <div className="glass-card empty-state" style={{ padding: 64, textAlign: 'center' }}>
                    <span className="material-symbols-outlined" style={{ fontSize: 48, color: 'var(--text-muted)', marginBottom: 16 }}>dns</span>
                    <h4 style={{ fontSize: 18, fontWeight: 700, marginBottom: 8 }}>No sources configured</h4>
                    <p style={{ color: 'var(--text-secondary)', marginBottom: 24 }}>Source data will appear here once configured.</p>
                    <button className="btn btn-primary" onClick={() => setIsAddModalOpen(true)}>
                        <span className="material-symbols-outlined">add</span>
                        Add Source
                    </button>
                </div>
            )}

            {isAddModalOpen && (
                <div className="modal-overlay">
                    <div className="modal">
                        <h3>Add New Source</h3>
                        {addError && <div className="error-banner">{addError}</div>}
                        <div className="form-group">
                            <label>Source Name</label>
                            <input
                                type="text"
                                className="input"
                                value={newSourceName}
                                onChange={e => setNewSourceName(e.target.value)}
                                placeholder="e.g. MyScraper1"
                            />
                        </div>
                        <div className="form-group">
                            <label>Source URL</label>
                            <input
                                type="url"
                                className="input"
                                value={newSourceUrl}
                                onChange={e => setNewSourceUrl(e.target.value)}
                                placeholder="https://example.com"
                            />
                        </div>
                        <div className="modal-actions" style={{ display: 'flex', gap: 12, marginTop: 24, justifyContent: 'flex-end' }}>
                            <button className="btn btn-secondary" onClick={() => {
                                setIsAddModalOpen(false);
                                setAddError('');
                            }}>Cancel</button>
                            <button className="btn btn-primary" onClick={handleAddSource}>Add Source</button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
