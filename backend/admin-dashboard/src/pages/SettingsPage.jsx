import { useState, useEffect } from 'react';
import api from '../api';

export default function SettingsPage() {
    const [settings, setSettings] = useState({});
    const [saving, setSaving] = useState(false);
    const [msg, setMsg] = useState('');

    useEffect(() => {
        api.get('/admin/config').then(r => setSettings(r.data || {})).catch(() => { });
    }, []);

    const update = (key, val) => setSettings(prev => ({ ...prev, [key]: val }));

    const save = async () => {
        setSaving(true);
        setMsg('');
        try {
            await api.put('/admin/config', { updates: settings });
            setMsg('Settings saved successfully!');
            setTimeout(() => setMsg(''), 3000);
        } catch {
            setMsg('Failed to save');
        } finally {
            setSaving(false);
        }
    };

    const resetAll = async () => {
        if (!confirm('Reset all settings to defaults? This cannot be undone.')) return;
        try { await api.put('/admin/config', { updates: {} }); window.location.reload(); } catch { }
    };

    return (
        <div className="page-scroll" style={{ position: 'relative', paddingBottom: 100 }}>
            <div className="page-header">
                <div className="page-header-text">
                    <div className="page-label">Admin Panel</div>
                    <h2>System Configuration</h2>
                    <p>Manage global app identity, scrapers, and preferences</p>
                </div>
            </div>

            <div className="grid-2">
                {/* Scraper Settings */}
                <div className="glass-card settings-card">
                    <div className="settings-card-header">
                        <span className="material-symbols-outlined">sync</span>
                        <h4>Scraper Configuration</h4>
                    </div>
                    <div className="form-group">
                        <label className="form-label">Auto-Sync Interval</label>
                        <select className="form-input" value={settings.sync_interval || '6h'} onChange={e => update('sync_interval', e.target.value)}>
                            <option value="6h">Every 6 hours</option>
                            <option value="12h">Every 12 hours</option>
                            <option value="24h">Every 24 hours</option>
                            <option value="weekly">Weekly</option>
                        </select>
                    </div>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
                        <div className="form-group">
                            <label className="form-label">Max Concurrent</label>
                            <input className="form-input" type="number" value={settings.max_concurrent || 5} onChange={e => update('max_concurrent', parseInt(e.target.value))} />
                            <div className="form-hint">Simultaneous threads</div>
                        </div>
                        <div className="form-group">
                            <label className="form-label">Timeout (sec)</label>
                            <input className="form-input" type="number" value={settings.timeout || 30} onChange={e => update('timeout', parseInt(e.target.value))} />
                            <div className="form-hint">Per request limit</div>
                        </div>
                    </div>
                    <div className="info-banner">
                        <span className="material-symbols-outlined">info</span>
                        <p>Increasing concurrent scrapers may speed up updates but can lead to IP blocks.</p>
                    </div>
                </div>

                {/* Version Control */}
                <div className="glass-card settings-card">
                    <div className="settings-card-header">
                        <span className="material-symbols-outlined">vibration</span>
                        <h4>Version Control</h4>
                    </div>
                    <div className="form-group">
                        <label className="form-label">Build Version</label>
                        <input className="form-input" type="text" value={settings.app_version || ''} onChange={e => update('app_version', e.target.value)} />
                    </div>
                    <div className="settings-row">
                        <div className="settings-row-text">
                            <h5>Maintenance Mode</h5>
                            <p>Redirects users to a maintenance page</p>
                        </div>
                        <label className="toggle">
                            <input type="checkbox" checked={!!settings.maintenance_mode} onChange={e => update('maintenance_mode', e.target.checked)} />
                            <span className="toggle-slider"></span>
                        </label>
                    </div>
                    <div className="settings-row">
                        <div className="settings-row-text">
                            <h5>Force Update</h5>
                            <p>Require users to download latest version</p>
                        </div>
                        <label className="toggle">
                            <input type="checkbox" checked={!!settings.force_update} onChange={e => update('force_update', e.target.checked)} />
                            <span className="toggle-slider"></span>
                        </label>
                    </div>
                </div>

                {/* Feature Toggles */}
                <div className="glass-card settings-card">
                    <div className="settings-card-header">
                        <span className="material-symbols-outlined">toggle_on</span>
                        <h4>Feature Toggles</h4>
                    </div>
                    {[
                        { key: 'push_notifications', icon: 'notifications_active', label: 'Push Notifications' },
                        { key: 'new_movie_alerts', icon: 'campaign', label: 'New Movie Alerts' },
                        { key: 'error_alerts', icon: 'report_problem', label: 'System Error Alerts' },
                        { key: 'user_comments', icon: 'reviews', label: 'User Comments' },
                    ].map(item => (
                        <div key={item.key} className="toggle-row">
                            <div className="toggle-row-left">
                                <span className="material-symbols-outlined">{item.icon}</span>
                                <span className="toggle-row-label">{item.label}</span>
                            </div>
                            <label className="toggle">
                                <input type="checkbox" checked={!!settings[item.key]} onChange={e => update(item.key, e.target.checked)} />
                                <span className="toggle-slider"></span>
                            </label>
                        </div>
                    ))}
                </div>

                {/* Maintenance & Backup */}
                <div className="glass-card settings-card">
                    <div className="settings-card-header">
                        <span className="material-symbols-outlined">backup</span>
                        <h4>Maintenance & Backup</h4>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <div>
                            <h5 style={{ fontSize: 14, fontWeight: 600 }}>Clear System Cache</h5>
                            <p style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 2 }}>Recommended after scraping updates</p>
                        </div>
                        <button className="btn btn-sm">
                            <span className="material-symbols-outlined">cleaning_services</span>
                            Clear Cache
                        </button>
                    </div>
                    <div style={{ marginTop: 16, paddingTop: 16, borderTop: '1px solid var(--border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <div>
                            <h5 style={{ fontSize: 14, fontWeight: 600 }}>Database Snapshot</h5>
                            <p style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 2 }}>Backup & restore database</p>
                        </div>
                        <div style={{ display: 'flex', gap: 8 }}>
                            <button className="btn btn-sm">
                                <span className="material-symbols-outlined">download</span>
                                Backup
                            </button>
                            <button className="btn btn-sm" style={{ borderColor: 'rgba(105,97,255,0.2)', background: 'var(--primary-dim)', color: 'var(--primary)' }}>
                                <span className="material-symbols-outlined">restore</span>
                                Restore
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            {/* Danger Zone */}
            <div className="danger-zone" style={{ marginTop: 24 }}>
                <div className="danger-zone-header">
                    <span className="material-symbols-outlined">warning</span>
                    <h4>Danger Zone</h4>
                </div>
                <div style={{ padding: 16, background: 'var(--red-bg)', borderRadius: 8, border: '1px solid rgba(239,68,68,0.1)', marginBottom: 24 }}>
                    <p style={{ fontSize: 13, color: '#fca5a5', lineHeight: 1.6 }}>Resetting settings will restore all configurations to default. This action cannot be undone.</p>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div>
                        <h5 style={{ fontSize: 14, fontWeight: 700 }}>Reset All Settings</h5>
                        <p style={{ fontSize: 11, color: 'var(--text-secondary)', marginTop: 2 }}>Flush all local and database configs</p>
                    </div>
                    <button className="btn" style={{ background: 'var(--red)', borderColor: 'transparent', color: 'white', fontWeight: 900, boxShadow: '0 4px 16px rgba(239,68,68,0.2)' }} onClick={resetAll}>
                        Reset System
                    </button>
                </div>
            </div>

            {/* Sticky Save Bar */}
            <div className="save-bar">
                <div className="save-bar-inner">
                    {msg && <p style={{ color: msg.includes('success') ? 'var(--green)' : 'var(--red)', fontStyle: 'normal', fontWeight: 600 }}>{msg}</p>}
                    <p>Unsaved changes will be lost.</p>
                    <button className="btn btn-primary btn-lg" onClick={save} disabled={saving}>
                        <span className="material-symbols-outlined">save</span>
                        {saving ? 'Saving...' : 'Save Changes'}
                    </button>
                </div>
            </div>
        </div>
    );
}
