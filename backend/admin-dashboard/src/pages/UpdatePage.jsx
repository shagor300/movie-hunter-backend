import { useState, useEffect, useCallback } from 'react';
import api from '../api';

export default function UpdatePage() {
    const [config, setConfig] = useState({
        current_version: '',
        update_url: '',
        is_force_update: false,
        whats_new: '',
    });
    const [loading, setLoading] = useState(true);
    const [publishing, setPublishing] = useState(false);
    const [msg, setMsg] = useState({ text: '', type: '' });
    const [history, setHistory] = useState([]);

    // Fetch current Remote Config values on mount
    const fetchConfig = useCallback(async () => {
        setLoading(true);
        try {
            const { data } = await api.get('/admin/remote-config');
            setConfig({
                current_version: data.current_version || '',
                update_url: data.update_url || '',
                is_force_update: data.is_force_update === 'true' || data.is_force_update === true,
                whats_new: data.whats_new || '',
            });
            if (data.history) setHistory(data.history);
        } catch {
            setMsg({ text: 'Failed to load config', type: 'error' });
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => { fetchConfig(); }, [fetchConfig]);

    const update = (key, val) => setConfig(prev => ({ ...prev, [key]: val }));

    // Publish to Firebase Remote Config
    const publish = async () => {
        if (!config.current_version.trim()) {
            setMsg({ text: 'Version is required', type: 'error' });
            return;
        }
        setPublishing(true);
        setMsg({ text: '', type: '' });
        try {
            await api.post('/admin/remote-config', {
                current_version: config.current_version,
                update_url: config.update_url,
                is_force_update: config.is_force_update,
                whats_new: config.whats_new,
            });
            setMsg({ text: '✅ Published to Firebase! Users will see the update on next app launch.', type: 'success' });
            setTimeout(() => setMsg({ text: '', type: '' }), 5000);
            fetchConfig();
        } catch (err) {
            setMsg({ text: err.response?.data?.detail || 'Publish failed', type: 'error' });
        } finally {
            setPublishing(false);
        }
    };

    // Parse version for display
    const parseVersion = (v) => {
        if (!v) return { name: '-', build: '-' };
        const parts = v.split('+');
        return { name: parts[0] || '-', build: parts[1] || '-' };
    };

    const ver = parseVersion(config.current_version);

    if (loading) {
        return (
            <div className="page-scroll" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: 400 }}>
                <div style={{ textAlign: 'center' }}>
                    <span className="material-symbols-outlined" style={{ fontSize: 48, color: 'var(--primary)', animation: 'spin 1s linear infinite' }}>autorenew</span>
                    <p style={{ color: 'var(--text-muted)', marginTop: 16 }}>Loading Remote Config...</p>
                </div>
            </div>
        );
    }

    return (
        <div className="page-scroll" style={{ position: 'relative', paddingBottom: 100 }}>
            <div className="page-header">
                <div className="page-header-text">
                    <div className="page-label">Firebase Remote Config</div>
                    <h2>In-App Update Manager</h2>
                    <p>Push app updates to all users instantly from this panel</p>
                </div>
            </div>

            {/* Current Live Version Banner */}
            <div className="glass-card" style={{ background: 'linear-gradient(135deg, rgba(105,97,255,0.08) 0%, rgba(0,229,160,0.06) 100%)', border: '1px solid rgba(105,97,255,0.15)', marginBottom: 20 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
                    <div style={{ width: 56, height: 56, borderRadius: 16, background: 'var(--primary-dim)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <span className="material-symbols-outlined" style={{ fontSize: 28, color: 'var(--primary)' }}>deployed_code</span>
                    </div>
                    <div style={{ flex: 1 }}>
                        <div style={{ fontSize: 11, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: 1, fontWeight: 600 }}>Live Version</div>
                        <div style={{ fontSize: 24, fontWeight: 800, color: 'var(--text-primary)', marginTop: 2 }}>{ver.name || 'Not Set'}</div>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                        <div style={{ fontSize: 11, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: 1, fontWeight: 600 }}>Build</div>
                        <div style={{ fontSize: 24, fontWeight: 800, color: 'var(--primary)', marginTop: 2 }}>#{ver.build}</div>
                    </div>
                    <div style={{ textAlign: 'center', marginLeft: 16 }}>
                        <div style={{
                            padding: '6px 14px',
                            borderRadius: 20,
                            fontSize: 12,
                            fontWeight: 700,
                            background: config.is_force_update ? 'rgba(239,68,68,0.12)' : 'rgba(0,229,160,0.12)',
                            color: config.is_force_update ? '#ef4444' : '#00e5a0',
                            border: `1px solid ${config.is_force_update ? 'rgba(239,68,68,0.2)' : 'rgba(0,229,160,0.2)'}`,
                        }}>
                            {config.is_force_update ? '🔴 Force' : '🟢 Optional'}
                        </div>
                    </div>
                </div>
            </div>

            <div className="grid-2">
                {/* Version Configuration */}
                <div className="glass-card settings-card">
                    <div className="settings-card-header">
                        <span className="material-symbols-outlined">system_update</span>
                        <h4>Version Configuration</h4>
                    </div>
                    <div className="form-group">
                        <label className="form-label">App Version</label>
                        <input
                            className="form-input"
                            type="text"
                            placeholder="e.g. 1.2.0+5"
                            value={config.current_version}
                            onChange={e => update('current_version', e.target.value)}
                        />
                        <div className="form-hint">Format: version_name+build_number (e.g. 1.2.0+5)</div>
                    </div>
                    <div className="form-group">
                        <label className="form-label">APK Download URL</label>
                        <input
                            className="form-input"
                            type="url"
                            placeholder="https://example.com/FlixHub_v1.2.0.apk"
                            value={config.update_url}
                            onChange={e => update('update_url', e.target.value)}
                        />
                        <div className="form-hint">Direct download link to the APK file</div>
                    </div>
                    <div className="settings-row" style={{ marginTop: 8 }}>
                        <div className="settings-row-text">
                            <h5>Force Update</h5>
                            <p>Users MUST update — non-dismissible dialog</p>
                        </div>
                        <label className="toggle">
                            <input type="checkbox" checked={config.is_force_update} onChange={e => update('is_force_update', e.target.checked)} />
                            <span className="toggle-slider"></span>
                        </label>
                    </div>
                    {config.is_force_update && (
                        <div className="info-banner" style={{ background: 'rgba(239,68,68,0.06)', borderColor: 'rgba(239,68,68,0.15)', marginTop: 12 }}>
                            <span className="material-symbols-outlined" style={{ color: '#ef4444' }}>warning</span>
                            <p style={{ color: '#fca5a5' }}>Force Update is ON — users cannot dismiss the update dialog. Use only for critical updates.</p>
                        </div>
                    )}
                </div>

                {/* Changelog */}
                <div className="glass-card settings-card">
                    <div className="settings-card-header">
                        <span className="material-symbols-outlined">article</span>
                        <h4>What's New (Changelog)</h4>
                    </div>
                    <div className="form-group">
                        <label className="form-label">Changelog Items</label>
                        <textarea
                            className="form-input"
                            rows="5"
                            placeholder={"Bug fixes and performance improvements\nNew dark mode theme\nImproved search speed\nAdded offline support"}
                            value={config.whats_new.replaceAll(',', '\n')}
                            onChange={e => update('whats_new', e.target.value.split('\n').map(s => s.trim()).filter(Boolean).join(','))}
                            style={{ resize: 'vertical', minHeight: 120, fontFamily: 'Inter, sans-serif', lineHeight: 1.8 }}
                        />
                        <div className="form-hint">One item per line — displayed as bullet points in the update dialog</div>
                    </div>

                    {/* Preview */}
                    {config.whats_new && (
                        <div style={{ marginTop: 16 }}>
                            <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: 1, marginBottom: 8 }}>Preview</div>
                            <div style={{ background: 'rgba(255,255,255,0.03)', borderRadius: 12, padding: 16, border: '1px solid var(--border)' }}>
                                {config.whats_new.split(',').filter(Boolean).map((item, i) => (
                                    <div key={i} style={{ display: 'flex', gap: 8, marginBottom: 6, alignItems: 'flex-start' }}>
                                        <span style={{ color: 'var(--primary)', fontWeight: 700 }}>•</span>
                                        <span style={{ fontSize: 13, color: 'var(--text-secondary)' }}>{item.trim()}</span>
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}
                </div>
            </div>

            {/* Update Summary Card */}
            <div className="glass-card" style={{ marginTop: 20 }}>
                <div className="settings-card-header">
                    <span className="material-symbols-outlined">checklist</span>
                    <h4>Publish Summary</h4>
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16, marginTop: 12 }}>
                    <div style={{ background: 'rgba(255,255,255,0.03)', borderRadius: 12, padding: 16, textAlign: 'center', border: '1px solid var(--border)' }}>
                        <span className="material-symbols-outlined" style={{ fontSize: 24, color: config.current_version ? 'var(--green)' : 'var(--text-muted)' }}>
                            {config.current_version ? 'check_circle' : 'radio_button_unchecked'}
                        </span>
                        <div style={{ fontSize: 12, fontWeight: 600, marginTop: 8, color: 'var(--text-secondary)' }}>Version</div>
                        <div style={{ fontSize: 14, fontWeight: 700, color: 'var(--text-primary)', marginTop: 2 }}>{ver.name || '—'}</div>
                    </div>
                    <div style={{ background: 'rgba(255,255,255,0.03)', borderRadius: 12, padding: 16, textAlign: 'center', border: '1px solid var(--border)' }}>
                        <span className="material-symbols-outlined" style={{ fontSize: 24, color: config.update_url ? 'var(--green)' : 'var(--text-muted)' }}>
                            {config.update_url ? 'check_circle' : 'radio_button_unchecked'}
                        </span>
                        <div style={{ fontSize: 12, fontWeight: 600, marginTop: 8, color: 'var(--text-secondary)' }}>APK URL</div>
                        <div style={{ fontSize: 14, fontWeight: 700, color: 'var(--text-primary)', marginTop: 2 }}>{config.update_url ? '✓ Set' : '—'}</div>
                    </div>
                    <div style={{ background: 'rgba(255,255,255,0.03)', borderRadius: 12, padding: 16, textAlign: 'center', border: '1px solid var(--border)' }}>
                        <span className="material-symbols-outlined" style={{ fontSize: 24, color: config.is_force_update ? '#ef4444' : 'var(--green)' }}>
                            {config.is_force_update ? 'gpp_maybe' : 'verified_user'}
                        </span>
                        <div style={{ fontSize: 12, fontWeight: 600, marginTop: 8, color: 'var(--text-secondary)' }}>Update Type</div>
                        <div style={{ fontSize: 14, fontWeight: 700, color: config.is_force_update ? '#ef4444' : 'var(--green)', marginTop: 2 }}>
                            {config.is_force_update ? 'Forced' : 'Optional'}
                        </div>
                    </div>
                    <div style={{ background: 'rgba(255,255,255,0.03)', borderRadius: 12, padding: 16, textAlign: 'center', border: '1px solid var(--border)' }}>
                        <span className="material-symbols-outlined" style={{ fontSize: 24, color: config.whats_new ? 'var(--green)' : 'var(--text-muted)' }}>
                            {config.whats_new ? 'check_circle' : 'radio_button_unchecked'}
                        </span>
                        <div style={{ fontSize: 12, fontWeight: 600, marginTop: 8, color: 'var(--text-secondary)' }}>Changelog</div>
                        <div style={{ fontSize: 14, fontWeight: 700, color: 'var(--text-primary)', marginTop: 2 }}>
                            {config.whats_new ? `${config.whats_new.split(',').filter(Boolean).length} items` : '—'}
                        </div>
                    </div>
                </div>
            </div>

            {/* Sticky Publish Bar */}
            <div className="save-bar">
                <div className="save-bar-inner">
                    {msg.text && (
                        <p style={{
                            color: msg.type === 'success' ? 'var(--green)' : 'var(--red)',
                            fontWeight: 600,
                            fontStyle: 'normal',
                        }}>{msg.text}</p>
                    )}
                    <p>Changes won't go live until published to Firebase.</p>
                    <button
                        className="btn btn-primary btn-lg"
                        onClick={publish}
                        disabled={publishing || !config.current_version.trim()}
                        style={{ minWidth: 180 }}
                    >
                        <span className="material-symbols-outlined">{publishing ? 'autorenew' : 'rocket_launch'}</span>
                        {publishing ? 'Publishing...' : 'Publish Update'}
                    </button>
                </div>
            </div>
        </div>
    );
}
