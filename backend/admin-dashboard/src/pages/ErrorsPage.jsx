import { useState, useEffect } from 'react';
import api from '../api';

export default function ErrorsPage() {
    const [errors, setErrors] = useState([]);
    const [filter, setFilter] = useState('all');
    const [search, setSearch] = useState('');
    const [expanded, setExpanded] = useState({});

    useEffect(() => {
        api.get('/admin/errors').then(r => setErrors(r.data.errors || [])).catch(() => { });
    }, []);

    const clearAll = async () => {
        if (!confirm('Clear all error logs?')) return;
        try { await api.delete('/admin/errors'); setErrors([]); } catch { }
    };

    const levelMap = { error: 'critical', warning: 'warning', info: 'info', critical: 'critical' };
    const levelColors = { critical: 'var(--red)', warning: 'var(--amber)', info: 'var(--blue)' };

    const filtered = errors.filter(e => {
        const level = levelMap[e.level?.toLowerCase()] || 'info';
        if (filter !== 'all' && level !== filter) return false;
        if (search && !(e.message || '').toLowerCase().includes(search.toLowerCase()) && !(e.source || '').toLowerCase().includes(search.toLowerCase())) return false;
        return true;
    });

    const counts = {
        critical: errors.filter(e => levelMap[e.level?.toLowerCase()] === 'critical').length,
        warning: errors.filter(e => levelMap[e.level?.toLowerCase()] === 'warning').length,
        info: errors.filter(e => levelMap[e.level?.toLowerCase()] === 'info').length,
    };

    const summaryCards = [
        { label: 'Critical Errors', count: counts.critical, icon: 'error', color: 'var(--red)', bg: 'var(--red-bg)', border: 'var(--red)' },
        { label: 'Warnings', count: counts.warning, icon: 'warning', color: 'var(--amber)', bg: 'var(--amber-bg)', border: 'var(--amber)' },
        { label: 'Info Logs', count: errors.length - counts.critical - counts.warning, icon: 'info', color: 'var(--blue)', bg: 'var(--blue-bg)', border: 'var(--blue)' },
        { label: 'Total Events', count: errors.length, icon: 'monitor_heart', color: 'var(--green)', bg: 'var(--green-bg)', border: 'var(--green)' },
    ];

    return (
        <div className="page-scroll">
            <div className="page-header">
                <div className="page-header-text">
                    <div className="page-label">Health Monitoring</div>
                    <h2>System Events</h2>
                    <p>Monitoring {errors.length} total system events</p>
                </div>
                <div className="page-actions">
                    <button className="btn btn-danger" onClick={clearAll}>
                        <span className="material-symbols-outlined">delete_sweep</span>
                        Clear All
                    </button>
                </div>
            </div>

            <div className="stats-grid" style={{ marginBottom: 24 }}>
                {summaryCards.map((card, i) => (
                    <div key={i} className="glass-card stat-card" style={{ borderBottom: `4px solid ${card.border}` }}>
                        <div className="stat-header">
                            <span style={{ fontSize: 14, color: 'var(--text-secondary)', fontWeight: 500 }}>{card.label}</span>
                            <span className="material-symbols-outlined" style={{ color: card.color, background: card.bg, padding: 8, borderRadius: 8 }}>{card.icon}</span>
                        </div>
                        <div className="stat-value" style={{ fontSize: 28 }}>{card.count}</div>
                    </div>
                ))}
            </div>

            <div className="glass-card filter-bar" style={{ marginBottom: 24 }}>
                <div className="filter-tabs">
                    {['all', 'critical', 'warning', 'info'].map(f => (
                        <button key={f} className={`filter-tab ${f !== 'all' ? f : ''} ${filter === f ? 'active' : ''}`} onClick={() => setFilter(f)}>
                            {f.charAt(0).toUpperCase() + f.slice(1)}
                        </button>
                    ))}
                </div>
                <div className="filter-divider" />
                <div className="filter-search">
                    <span className="material-symbols-outlined">search</span>
                    <input placeholder="Filter by source or message..." value={search} onChange={e => setSearch(e.target.value)} />
                </div>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                {filtered.map((err, i) => {
                    const level = levelMap[err.level?.toLowerCase()] || 'info';
                    return (
                        <div key={i} className={`glass-card error-card ${level}`}>
                            <div className="error-card-header">
                                <div className="error-card-meta">
                                    <span className={`badge badge-solid-${level === 'critical' ? 'red' : level === 'warning' ? 'amber' : 'blue'}`}>
                                        {level}
                                    </span>
                                    <span style={{ fontSize: 12, color: 'var(--text-muted)' }}>{err.timestamp || 'Unknown time'}</span>
                                </div>
                                <div className="error-card-actions">
                                    <button className="btn btn-sm" style={{ borderColor: 'rgba(16,185,129,0.2)', color: 'var(--green)' }}>Mark Resolved</button>
                                </div>
                            </div>
                            <div className="error-card-title">{err.message || 'Unknown error'}</div>
                            {err.source && (
                                <div className="error-card-source">
                                    <span>Source:</span>
                                    <code>{err.source}</code>
                                </div>
                            )}
                            {err.traceback && (
                                <>
                                    <button
                                        className="btn btn-ghost btn-sm" style={{ marginTop: 12, color: 'var(--primary)', fontWeight: 700, padding: '4px 0' }}
                                        onClick={() => setExpanded(p => ({ ...p, [i]: !p[i] }))}
                                    >
                                        <span className="material-symbols-outlined" style={{ fontSize: 16, transform: expanded[i] ? 'rotate(180deg)' : 'none', transition: '0.2s' }}>expand_more</span>
                                        {expanded[i] ? 'HIDE' : 'VIEW'} STACK TRACE
                                    </button>
                                    {expanded[i] && <div className="error-trace">{err.traceback}</div>}
                                </>
                            )}
                        </div>
                    );
                })}

                {filtered.length === 0 && (
                    <div className="glass-card" style={{ padding: 64, textAlign: 'center', borderRadius: 24, border: '2px dashed rgba(255,255,255,0.1)' }}>
                        <div style={{ width: 96, height: 96, background: 'var(--green-bg)', color: 'var(--green)', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 24px' }}>
                            <span className="material-symbols-outlined" style={{ fontSize: 48 }}>check_circle</span>
                        </div>
                        <h4 style={{ fontSize: 20, fontWeight: 700, marginBottom: 8 }}>Systems Nominal</h4>
                        <p style={{ color: 'var(--text-secondary)' }}>No unresolved errors found.</p>
                    </div>
                )}
            </div>
        </div>
    );
}
