import { useState, useEffect, useCallback } from 'react';
import { HashRouter, Routes, Route, Navigate, useLocation, useNavigate } from 'react-router-dom';
import {
    LayoutDashboard, Link2, Search, Activity, AlertTriangle,
    Settings, LogOut, Bell, ChevronRight, RefreshCw, Plus, Trash2, X
} from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import api from './api';
import './index.css';

// ─── Auth Context ────────────────────────────────────────────────────

function useAuth() {
    const [token, setToken] = useState(localStorage.getItem('admin_token'));
    const [user, setUser] = useState(JSON.parse(localStorage.getItem('admin_user') || 'null'));

    const login = async (username, password) => {
        const res = await api.post('/admin/login', { username, password });
        if (res.data.success) {
            localStorage.setItem('admin_token', res.data.token);
            localStorage.setItem('admin_user', JSON.stringify({ username: res.data.username, role: res.data.role }));
            setToken(res.data.token);
            setUser({ username: res.data.username, role: res.data.role });
        }
        return res.data;
    };

    const logout = () => {
        api.post('/admin/logout').catch(() => { });
        localStorage.removeItem('admin_token');
        localStorage.removeItem('admin_user');
        setToken(null);
        setUser(null);
    };

    return { token, user, login, logout, isAuthenticated: !!token };
}

// ─── Login Page ──────────────────────────────────────────────────────

function LoginPage({ onLogin }) {
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        try {
            await onLogin(username, password);
        } catch (err) {
            setError(err.response?.data?.detail || 'Login failed');
        }
        setLoading(false);
    };

    return (
        <div className="login-container">
            <form className="login-card" onSubmit={handleSubmit}>
                <h1>MovieHub</h1>
                <p className="subtitle">Admin Dashboard</p>
                {error && <div className="login-error">{error}</div>}
                <div className="form-group">
                    <label className="form-label">Username</label>
                    <input className="form-input" value={username} onChange={(e) => setUsername(e.target.value)}
                        placeholder="admin" autoFocus required />
                </div>
                <div className="form-group">
                    <label className="form-label">Password</label>
                    <input className="form-input" type="password" value={password}
                        onChange={(e) => setPassword(e.target.value)} placeholder="••••••••" required />
                </div>
                <button className="btn btn-primary" disabled={loading}>
                    {loading ? 'Signing in...' : 'Sign In'}
                </button>
            </form>
        </div>
    );
}

// ─── Sidebar ─────────────────────────────────────────────────────────

const NAV_ITEMS = [
    { path: '/', icon: LayoutDashboard, label: 'Dashboard' },
    { path: '/manual-links', icon: Link2, label: 'Manual Links' },
    { path: '/search', icon: Search, label: 'Search Analytics' },
    { path: '/sources', icon: Activity, label: 'Sources' },
    { path: '/errors', icon: AlertTriangle, label: 'Error Logs' },
    { path: '/settings', icon: Settings, label: 'Settings' },
];

function Sidebar({ user, onLogout }) {
    const location = useLocation();
    const navigate = useNavigate();

    return (
        <aside className="sidebar">
            <div className="sidebar-logo">
                <h1>MovieHub</h1>
                <span>Admin Panel</span>
            </div>
            <nav className="sidebar-nav">
                {NAV_ITEMS.map((item) => (
                    <button key={item.path}
                        className={`nav-item ${location.pathname === item.path ? 'active' : ''}`}
                        onClick={() => navigate(item.path)}>
                        <item.icon size={18} />
                        <span>{item.label}</span>
                    </button>
                ))}
            </nav>
            <div className="sidebar-footer">
                <div style={{ fontSize: 12, color: 'var(--text-muted)', marginBottom: 8 }}>
                    Signed in as <strong style={{ color: 'var(--text-primary)' }}>{user?.username}</strong>
                </div>
                <button className="logout-btn" onClick={onLogout}>
                    <LogOut size={14} /> Sign Out
                </button>
            </div>
        </aside>
    );
}

// ─── Dashboard Page ──────────────────────────────────────────────────

function DashboardPage() {
    const [stats, setStats] = useState(null);
    const [chart, setChart] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        Promise.all([
            api.get('/admin/dashboard/stats'),
            api.get('/admin/dashboard/activity-chart?days=7'),
        ]).then(([s, c]) => {
            setStats(s.data);
            setChart(c.data);
        }).finally(() => setLoading(false));
    }, []);

    if (loading) return <div className="loading-spinner"><div className="spinner" /></div>;

    const cards = [
        { label: "Today's Searches", value: stats?.today_searches || 0, color: 'var(--blue)', bg: 'var(--blue-bg)', icon: Search },
        { label: "Today's Downloads", value: stats?.today_downloads || 0, color: 'var(--green)', bg: 'var(--green-bg)', icon: ChevronRight },
        { label: 'Manual Links', value: stats?.total_manual_links || 0, color: 'var(--accent)', bg: 'var(--accent-glow)', icon: Link2 },
        { label: 'Unresolved Errors', value: stats?.unresolved_errors || 0, color: 'var(--red)', bg: 'var(--red-bg)', icon: AlertTriangle },
    ];

    // Merge search/download chart data
    const chartData = (chart?.searches || []).map((s) => {
        const dl = (chart?.downloads || []).find((d) => d.date === s.date);
        return { date: s.date?.slice(5), searches: s.count, downloads: dl?.count || 0 };
    });

    return (
        <>
            <div className="page-header">
                <h2>Dashboard</h2>
                <p>Overview of your MovieHub backend</p>
            </div>

            <div className="stats-grid">
                {cards.map((c) => (
                    <div className="stat-card" key={c.label}>
                        <div className="stat-icon" style={{ background: c.bg }}>
                            <c.icon size={20} color={c.color} />
                        </div>
                        <div className="stat-value" style={{ color: c.color }}>{c.value}</div>
                        <div className="stat-label">{c.label}</div>
                    </div>
                ))}
            </div>

            {chartData.length > 0 && (
                <div className="card">
                    <div className="card-header"><h3>📊 Last 7 Days Activity</h3></div>
                    <ResponsiveContainer width="100%" height={280}>
                        <LineChart data={chartData}>
                            <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                            <XAxis dataKey="date" stroke="var(--text-muted)" fontSize={12} />
                            <YAxis stroke="var(--text-muted)" fontSize={12} />
                            <Tooltip contentStyle={{ background: 'var(--bg-card)', border: '1px solid var(--border)', borderRadius: 8 }} />
                            <Line type="monotone" dataKey="searches" stroke="var(--blue)" strokeWidth={2} dot={{ r: 4 }} />
                            <Line type="monotone" dataKey="downloads" stroke="var(--green)" strokeWidth={2} dot={{ r: 4 }} />
                        </LineChart>
                    </ResponsiveContainer>
                </div>
            )}

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
                <div className="card">
                    <div className="card-header"><h3>🔍 Top Searches (7d)</h3></div>
                    {stats?.top_searches?.length ? (
                        <table className="data-table">
                            <thead><tr><th>Query</th><th>Count</th></tr></thead>
                            <tbody>
                                {stats.top_searches.map((s, i) => (
                                    <tr key={i}><td>{s.query}</td><td>{s.count}</td></tr>
                                ))}
                            </tbody>
                        </table>
                    ) : <div className="empty-state">No searches yet</div>}
                </div>

                <div className="card">
                    <div className="card-header"><h3>🔥 Top Downloads (7d)</h3></div>
                    {stats?.top_downloads?.length ? (
                        <table className="data-table">
                            <thead><tr><th>Movie</th><th>Count</th></tr></thead>
                            <tbody>
                                {stats.top_downloads.map((d, i) => (
                                    <tr key={i}><td>{d.movie_title}</td><td>{d.count}</td></tr>
                                ))}
                            </tbody>
                        </table>
                    ) : <div className="empty-state">No downloads yet</div>}
                </div>
            </div>

            {stats?.recent_errors?.length > 0 && (
                <div className="card" style={{ marginTop: 16 }}>
                    <div className="card-header"><h3>⚠️ Recent Errors (24h)</h3></div>
                    <table className="data-table">
                        <thead><tr><th>Severity</th><th>Source</th><th>Message</th><th>Time</th></tr></thead>
                        <tbody>
                            {stats.recent_errors.map((e) => (
                                <tr key={e.id}>
                                    <td><span className={`badge badge-${e.severity === 'critical' ? 'red' : e.severity === 'warning' ? 'yellow' : 'blue'}`}>{e.severity}</span></td>
                                    <td>{e.source}</td>
                                    <td style={{ maxWidth: 300, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{e.message}</td>
                                    <td style={{ fontSize: 12 }}>{e.created_at?.slice(11, 19)}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            )}
        </>
    );
}

// ─── Manual Links Page ───────────────────────────────────────────────

function ManualLinksPage() {
    const [links, setLinks] = useState([]);
    const [total, setTotal] = useState(0);
    const [search, setSearch] = useState('');
    const [loading, setLoading] = useState(true);
    const [showAdd, setShowAdd] = useState(false);

    const fetchLinks = useCallback(async () => {
        setLoading(true);
        try {
            const res = await api.get('/admin/manual-links', { params: { search, limit: 50 } });
            setLinks(res.data.links || []);
            setTotal(res.data.total || 0);
        } catch { /* ignore */ }
        setLoading(false);
    }, [search]);

    useEffect(() => { fetchLinks(); }, [fetchLinks]);

    const deleteLink = async (id) => {
        if (!confirm('Delete this link?')) return;
        await api.delete(`/admin/manual-links/${id}`);
        fetchLinks();
    };

    return (
        <>
            <div className="page-header">
                <h2>Manual Links</h2>
                <p>Priority links for movies — checked before scraping ({total} total)</p>
            </div>

            <div style={{ display: 'flex', gap: 12, marginBottom: 20 }}>
                <input className="form-input" style={{ maxWidth: 360 }} placeholder="Search by movie title..."
                    value={search} onChange={(e) => setSearch(e.target.value)} />
                <button className="btn btn-primary" onClick={() => setShowAdd(true)}>
                    <Plus size={16} /> Add Links
                </button>
            </div>

            {loading ? <div className="loading-spinner"><div className="spinner" /></div> : (
                <div className="card">
                    {links.length ? (
                        <table className="data-table">
                            <thead><tr><th>Movie</th><th>Source</th><th>URL</th><th>Priority</th><th>Status</th><th></th></tr></thead>
                            <tbody>
                                {links.map((l) => (
                                    <tr key={l.id}>
                                        <td>
                                            <strong style={{ color: 'var(--text-primary)' }}>{l.movie_title}</strong>
                                            {l.movie_year && <span style={{ marginLeft: 6, fontSize: 12, color: 'var(--text-muted)' }}>({l.movie_year})</span>}
                                        </td>
                                        <td><span className="badge badge-blue">{l.source_name}</span></td>
                                        <td style={{ maxWidth: 220, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                                            <a href={l.source_url} target="_blank" rel="noreferrer">{l.source_url}</a>
                                        </td>
                                        <td style={{ fontWeight: 600, color: 'var(--accent-light)' }}>{l.priority}</td>
                                        <td><span className={`badge badge-${l.status === 'active' ? 'green' : 'red'}`}>{l.status}</span></td>
                                        <td><button className="btn btn-danger btn-sm" onClick={() => deleteLink(l.id)}><Trash2 size={14} /></button></td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    ) : <div className="empty-state">No manual links found. Add some to speed up movie lookups!</div>}
                </div>
            )}

            {showAdd && <AddLinksModal onClose={() => setShowAdd(false)} onSuccess={fetchLinks} />}
        </>
    );
}

function AddLinksModal({ onClose, onSuccess }) {
    const [movieTitle, setMovieTitle] = useState('');
    const [tmdbId, setTmdbId] = useState('');
    const [year, setYear] = useState('');
    const [language, setLanguage] = useState('');
    const [links, setLinks] = useState([{ source_name: 'hdhub4u', source_url: '', priority: 1 }]);
    const [tmdbResults, setTmdbResults] = useState([]);
    const [saving, setSaving] = useState(false);

    const searchTmdb = async () => {
        if (!movieTitle) return;
        try {
            const res = await api.get('/admin/tmdb/search', { params: { query: movieTitle } });
            setTmdbResults(res.data.results?.slice(0, 5) || []);
        } catch { /* ignore */ }
    };

    const selectTmdb = (movie) => {
        setMovieTitle(movie.title);
        setTmdbId(movie.id);
        setYear(movie.release_date?.split('-')[0] || '');
        setTmdbResults([]);
    };

    const addLink = () => setLinks([...links, { source_name: 'hdhub4u', source_url: '', priority: 1 }]);
    const removeLink = (i) => setLinks(links.filter((_, idx) => idx !== i));
    const updateLink = (i, field, val) => {
        const next = [...links];
        next[i][field] = val;
        setLinks(next);
    };

    const submit = async () => {
        if (!movieTitle || !links.some((l) => l.source_url)) return;
        setSaving(true);
        try {
            await api.post('/admin/manual-links', {
                tmdb_id: tmdbId ? parseInt(tmdbId) : null,
                movie_title: movieTitle,
                year: year ? parseInt(year) : null,
                language: language || null,
                poster_url: null,
                links: links.filter((l) => l.source_url),
            });
            onSuccess();
            onClose();
        } catch (err) {
            alert('Failed to add links: ' + (err.response?.data?.detail || err.message));
        }
        setSaving(false);
    };

    return (
        <div className="modal-overlay" onClick={onClose}>
            <div className="modal" onClick={(e) => e.stopPropagation()}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
                    <h3 style={{ margin: 0 }}>Add Manual Links</h3>
                    <button className="btn btn-sm" onClick={onClose}><X size={16} /></button>
                </div>

                <div className="form-group">
                    <label className="form-label">Movie Title</label>
                    <div style={{ display: 'flex', gap: 8 }}>
                        <input className="form-input" value={movieTitle} onChange={(e) => setMovieTitle(e.target.value)}
                            placeholder="e.g. Inception" />
                        <button className="btn" onClick={searchTmdb}>TMDB</button>
                    </div>
                    {tmdbResults.length > 0 && (
                        <div style={{ background: 'var(--bg-primary)', border: '1px solid var(--border)', borderRadius: 8, marginTop: 8, maxHeight: 200, overflowY: 'auto' }}>
                            {tmdbResults.map((m) => (
                                <div key={m.id} style={{ padding: '8px 12px', cursor: 'pointer', fontSize: 13, borderBottom: '1px solid var(--border)' }}
                                    onClick={() => selectTmdb(m)}>
                                    <strong>{m.title}</strong> <span style={{ color: 'var(--text-muted)' }}>({m.release_date?.slice(0, 4)}) — ID: {m.id}</span>
                                </div>
                            ))}
                        </div>
                    )}
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 12 }}>
                    <div className="form-group">
                        <label className="form-label">TMDB ID</label>
                        <input className="form-input" value={tmdbId} onChange={(e) => setTmdbId(e.target.value)} placeholder="optional" />
                    </div>
                    <div className="form-group">
                        <label className="form-label">Year</label>
                        <input className="form-input" value={year} onChange={(e) => setYear(e.target.value)} placeholder="2025" />
                    </div>
                    <div className="form-group">
                        <label className="form-label">Language</label>
                        <input className="form-input" value={language} onChange={(e) => setLanguage(e.target.value)} placeholder="Hindi" />
                    </div>
                </div>

                <h4 style={{ fontSize: 14, marginBottom: 12, color: 'var(--text-secondary)' }}>Source Links</h4>
                {links.map((link, i) => (
                    <div key={i} style={{ display: 'flex', gap: 8, marginBottom: 8, alignItems: 'center' }}>
                        <select className="form-input" style={{ width: 140 }} value={link.source_name}
                            onChange={(e) => updateLink(i, 'source_name', e.target.value)}>
                            <option value="hdhub4u">HDHub4u</option>
                            <option value="skymovieshd">SkyMoviesHD</option>
                            <option value="cinefreak">CinemaFreak</option>
                            <option value="katmoviehd">KatMovieHD</option>
                        </select>
                        <input className="form-input" value={link.source_url} onChange={(e) => updateLink(i, 'source_url', e.target.value)}
                            placeholder="https://..." style={{ flex: 1 }} />
                        <input className="form-input" type="number" value={link.priority} onChange={(e) => updateLink(i, 'priority', parseInt(e.target.value) || 1)}
                            style={{ width: 70 }} title="Priority" />
                        {links.length > 1 && <button className="btn btn-danger btn-sm" onClick={() => removeLink(i)}><X size={14} /></button>}
                    </div>
                ))}
                <button className="btn btn-sm" onClick={addLink} style={{ marginBottom: 8 }}><Plus size={14} /> Add another link</button>

                <div className="modal-actions">
                    <button className="btn" onClick={onClose}>Cancel</button>
                    <button className="btn btn-primary" onClick={submit} disabled={saving}>{saving ? 'Saving...' : 'Save Links'}</button>
                </div>
            </div>
        </div>
    );
}

// ─── Search Analytics Page ───────────────────────────────────────────

function SearchPage() {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        api.get('/admin/search-analytics?days=30').then((res) => setData(res.data)).finally(() => setLoading(false));
    }, []);

    if (loading) return <div className="loading-spinner"><div className="spinner" /></div>;

    return (
        <>
            <div className="page-header">
                <h2>Search Analytics</h2>
                <p>What users are searching for (last 30 days)</p>
            </div>

            {data?.daily_searches?.length > 0 && (
                <div className="card">
                    <div className="card-header"><h3>📈 Search Volume</h3></div>
                    <ResponsiveContainer width="100%" height={250}>
                        <LineChart data={data.daily_searches.map((d) => ({ date: d.date?.slice(5), count: d.count }))}>
                            <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                            <XAxis dataKey="date" stroke="var(--text-muted)" fontSize={12} />
                            <YAxis stroke="var(--text-muted)" fontSize={12} />
                            <Tooltip contentStyle={{ background: 'var(--bg-card)', border: '1px solid var(--border)', borderRadius: 8 }} />
                            <Line type="monotone" dataKey="count" stroke="var(--blue)" strokeWidth={2} dot={{ r: 3 }} />
                        </LineChart>
                    </ResponsiveContainer>
                </div>
            )}

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
                <div className="card">
                    <div className="card-header"><h3>🔝 Top Queries</h3></div>
                    {data?.top_queries?.length ? (
                        <table className="data-table">
                            <thead><tr><th>Query</th><th>Count</th></tr></thead>
                            <tbody>{data.top_queries.slice(0, 20).map((q, i) => <tr key={i}><td>{q.query}</td><td>{q.count}</td></tr>)}</tbody>
                        </table>
                    ) : <div className="empty-state">No searches recorded yet</div>}
                </div>

                <div className="card">
                    <div className="card-header"><h3>❌ Zero-Result Searches</h3></div>
                    {data?.zero_results?.length ? (
                        <table className="data-table">
                            <thead><tr><th>Query</th><th>Count</th></tr></thead>
                            <tbody>{data.zero_results.map((q, i) => <tr key={i}><td>{q.query}</td><td>{q.count}</td></tr>)}</tbody>
                        </table>
                    ) : <div className="empty-state">No zero-result searches 🎉</div>}
                </div>
            </div>
        </>
    );
}

// ─── Sources Page ────────────────────────────────────────────────────

function SourcesPage() {
    const [sources, setSources] = useState([]);
    const [loading, setLoading] = useState(true);

    const fetchSources = async () => {
        setLoading(true);
        try { const res = await api.get('/admin/sources'); setSources(res.data); }
        catch { /* ignore */ }
        setLoading(false);
    };

    useEffect(() => { fetchSources(); }, []);

    const toggle = async (name, current) => {
        await api.put(`/admin/sources/${name}/toggle?enabled=${!current}`);
        fetchSources();
    };

    if (loading) return <div className="loading-spinner"><div className="spinner" /></div>;

    return (
        <>
            <div className="page-header">
                <h2>Sources</h2>
                <p>Monitor and manage scraper sources</p>
            </div>

            <div className="stats-grid" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))' }}>
                {sources.map((s) => (
                    <div className="card" key={s.source_name} style={{ padding: 22 }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
                            <h3 style={{ fontSize: 16, color: 'var(--text-primary)', textTransform: 'capitalize' }}>{s.source_name}</h3>
                            <span className={`badge ${s.is_enabled ? 'badge-green' : 'badge-red'}`}>
                                {s.is_enabled ? 'Enabled' : 'Disabled'}
                            </span>
                        </div>
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginBottom: 14, fontSize: 13 }}>
                            <div><span style={{ color: 'var(--text-muted)' }}>Online:</span> <span className={`badge badge-${s.is_online ? 'green' : 'red'}`}>{s.is_online ? 'Yes' : 'No'}</span></div>
                            <div><span style={{ color: 'var(--text-muted)' }}>Movies:</span> <strong>{s.total_movies}</strong></div>
                            <div><span style={{ color: 'var(--text-muted)' }}>Success:</span> <strong>{(s.success_rate * 100).toFixed(0)}%</strong></div>
                            <div><span style={{ color: 'var(--text-muted)' }}>Failures:</span> <strong>{s.consecutive_failures}</strong></div>
                        </div>
                        <button className={`btn btn-sm ${s.is_enabled ? 'btn-danger' : 'btn-primary'}`}
                            onClick={() => toggle(s.source_name, s.is_enabled)}>
                            {s.is_enabled ? 'Disable' : 'Enable'}
                        </button>
                    </div>
                ))}
            </div>
        </>
    );
}

// ─── Error Logs Page ─────────────────────────────────────────────────

function ErrorsPage() {
    const [errors, setErrors] = useState([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState('');

    const fetchErrors = async () => {
        setLoading(true);
        try {
            const params = filter ? { severity: filter } : {};
            const res = await api.get('/admin/errors', { params });
            setErrors(res.data);
        } catch { /* ignore */ }
        setLoading(false);
    };

    useEffect(() => { fetchErrors(); }, [filter]);

    const resolve = async (id) => {
        await api.put(`/admin/errors/${id}/resolve`);
        fetchErrors();
    };

    if (loading) return <div className="loading-spinner"><div className="spinner" /></div>;

    return (
        <>
            <div className="page-header">
                <h2>Error Logs</h2>
                <p>Track and resolve errors from scrapers and APIs</p>
            </div>

            <div style={{ display: 'flex', gap: 8, marginBottom: 20 }}>
                {['', 'critical', 'warning', 'info'].map((f) => (
                    <button key={f} className={`btn btn-sm ${filter === f ? 'btn-primary' : ''}`}
                        onClick={() => setFilter(f)}>
                        {f || 'All'}
                    </button>
                ))}
                <button className="btn btn-sm" onClick={fetchErrors} style={{ marginLeft: 'auto' }}><RefreshCw size={14} /> Refresh</button>
            </div>

            <div className="card">
                {errors.length ? (
                    <table className="data-table">
                        <thead><tr><th>Severity</th><th>Source</th><th>Message</th><th>Time</th><th>Status</th><th></th></tr></thead>
                        <tbody>
                            {errors.map((e) => (
                                <tr key={e.id}>
                                    <td><span className={`badge badge-${e.severity === 'critical' ? 'red' : e.severity === 'warning' ? 'yellow' : 'blue'}`}>{e.severity}</span></td>
                                    <td style={{ fontSize: 13 }}>{e.source}</td>
                                    <td style={{ maxWidth: 350, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', fontSize: 13 }}>{e.message}</td>
                                    <td style={{ fontSize: 12, color: 'var(--text-muted)', whiteSpace: 'nowrap' }}>{e.created_at?.slice(0, 16).replace('T', ' ')}</td>
                                    <td>{e.resolved ? <span className="badge badge-green">Resolved</span> : <span className="badge badge-yellow">Open</span>}</td>
                                    <td>{!e.resolved && <button className="btn btn-sm" onClick={() => resolve(e.id)}>Resolve</button>}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                ) : <div className="empty-state">No errors — everything is running smoothly! 🎉</div>}
            </div>
        </>
    );
}

// ─── Settings Page ───────────────────────────────────────────────────

function SettingsPage() {
    const [config, setConfig] = useState({});
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [edits, setEdits] = useState({});

    useEffect(() => {
        api.get('/admin/config').then((res) => {
            setConfig(res.data);
            const initial = {};
            for (const [key, obj] of Object.entries(res.data)) {
                initial[key] = obj.value;
            }
            setEdits(initial);
        }).finally(() => setLoading(false));
    }, []);

    const save = async () => {
        setSaving(true);
        try {
            await api.put('/admin/config', { updates: edits });
            alert('Settings saved!');
        } catch { alert('Failed to save'); }
        setSaving(false);
    };

    if (loading) return <div className="loading-spinner"><div className="spinner" /></div>;

    return (
        <>
            <div className="page-header">
                <h2>Settings</h2>
                <p>App configuration and preferences</p>
            </div>

            <div className="card">
                {Object.entries(config).map(([key, obj]) => (
                    <div className="form-group" key={key}>
                        <label className="form-label">{key.replace(/_/g, ' ')}</label>
                        <input className="form-input" value={edits[key] || ''}
                            onChange={(e) => setEdits({ ...edits, [key]: e.target.value })} />
                        {obj.description && <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 4 }}>{obj.description}</div>}
                    </div>
                ))}
                <button className="btn btn-primary" onClick={save} disabled={saving}>
                    {saving ? 'Saving...' : 'Save Changes'}
                </button>
            </div>
        </>
    );
}

// ─── App Root ────────────────────────────────────────────────────────

function AuthenticatedApp({ user, logout }) {
    return (
        <div className="app-layout">
            <Sidebar user={user} onLogout={logout} />
            <main className="main-content">
                <Routes>
                    <Route path="/" element={<DashboardPage />} />
                    <Route path="/manual-links" element={<ManualLinksPage />} />
                    <Route path="/search" element={<SearchPage />} />
                    <Route path="/sources" element={<SourcesPage />} />
                    <Route path="/errors" element={<ErrorsPage />} />
                    <Route path="/settings" element={<SettingsPage />} />
                    <Route path="*" element={<Navigate to="/" />} />
                </Routes>
            </main>
        </div>
    );
}

export default function App() {
    const { isAuthenticated, user, login, logout } = useAuth();

    return (
        <HashRouter>
            {isAuthenticated ? (
                <AuthenticatedApp user={user} logout={logout} />
            ) : (
                <Routes>
                    <Route path="*" element={<LoginPage onLogin={login} />} />
                </Routes>
            )}
        </HashRouter>
    );
}
