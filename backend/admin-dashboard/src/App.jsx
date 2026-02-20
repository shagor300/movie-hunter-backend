import { useState, useEffect, useCallback } from 'react';
import { HashRouter, Routes, Route, Navigate, useLocation, useNavigate } from 'react-router-dom';
import {
    LayoutDashboard, Link2, Search, Activity, AlertTriangle,
    Settings, LogOut, Bell, ChevronRight, RefreshCw, Plus, Trash2, X,
    Film, TrendingUp, TrendingDown, Minus, ChevronLeft, Check,
    Shield, Key, FileText, Database, Eye, EyeOff, Zap, Download
} from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, AreaChart, Area } from 'recharts';
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
    const [showPass, setShowPass] = useState(false);

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
                <p className="subtitle">Admin Login</p>
                <div className="login-badge">
                    <Shield size={14} /> Authorized Personnel Access Only
                </div>
                {error && <div className="login-error">{error}</div>}
                <div className="form-group">
                    <label className="form-label">Username</label>
                    <input className="form-input" value={username} onChange={(e) => setUsername(e.target.value)}
                        placeholder="Enter your username" autoFocus required />
                </div>
                <div className="form-group">
                    <label className="form-label">Password</label>
                    <div style={{ position: 'relative' }}>
                        <input className="form-input" type={showPass ? 'text' : 'password'} value={password}
                            onChange={(e) => setPassword(e.target.value)} placeholder="••••••••" required />
                        <button type="button" onClick={() => setShowPass(!showPass)}
                            style={{ position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>
                            {showPass ? <EyeOff size={16} /> : <Eye size={16} />}
                        </button>
                    </div>
                </div>
                <button className="btn btn-primary" disabled={loading}>
                    {loading ? 'Signing in...' : 'Sign In'}
                </button>
                <div className="login-footer">
                    <a href="#">Support Center</a>
                    <a href="#">Privacy Policy</a>
                </div>
            </form>
        </div>
    );
}

// ─── Sidebar ─────────────────────────────────────────────────────────

const NAV_ITEMS = [
    { section: 'System Management' },
    { path: '/', icon: LayoutDashboard, label: 'Dashboard' },
    { path: '/sources', icon: Database, label: 'Sources' },
    { path: '/movies', icon: Film, label: 'Movies' },
    { path: '/search', icon: Search, label: 'Analytics' },
    { section: 'Configuration' },
    { path: '/errors', icon: AlertTriangle, label: 'Error Logs' },
    { path: '/settings', icon: Settings, label: 'Settings' },
];

function Sidebar({ user, onLogout }) {
    const location = useLocation();
    const navigate = useNavigate();

    const initials = user?.username?.slice(0, 2).toUpperCase() || 'AD';

    return (
        <aside className="sidebar">
            <div className="sidebar-logo">
                <h1>MovieHub Admin</h1>
                <span>Super Admin Console</span>
            </div>
            <nav className="sidebar-nav">
                {NAV_ITEMS.map((item, i) =>
                    item.section ? (
                        <div className="sidebar-section-label" key={`s-${i}`}>{item.section}</div>
                    ) : (
                        <button key={item.path}
                            className={`nav-item ${location.pathname === item.path ? 'active' : ''}`}
                            onClick={() => navigate(item.path)}>
                            <item.icon size={18} />
                            <span>{item.label}</span>
                        </button>
                    )
                )}
            </nav>
            <div className="sidebar-footer">
                <div className="sidebar-user">
                    <div className="sidebar-avatar">{initials}</div>
                    <div className="sidebar-user-info">
                        <div className="sidebar-user-name">{user?.username || 'Admin'}</div>
                        <div className="sidebar-user-role">{user?.role || 'Super Admin'}</div>
                    </div>
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
        { label: 'Total Movies', value: stats?.total_manual_links || 0, color: 'var(--accent)', bg: 'var(--accent-glow)', icon: Film },
        { label: "Today's Searches", value: stats?.today_searches || 0, color: 'var(--blue)', bg: 'var(--blue-bg)', icon: Search },
        { label: 'Downloads', value: stats?.today_downloads || 0, color: 'var(--green)', bg: 'var(--green-bg)', icon: Download },
        { label: 'Active Sources', value: stats?.sources?.filter(s => s.is_enabled)?.length || 0, color: 'var(--cyan)', bg: 'var(--cyan-bg)', icon: Zap },
    ];

    const chartData = (chart?.searches || []).map((s) => {
        const dl = (chart?.downloads || []).find((d) => d.date === s.date);
        return { date: s.date?.slice(5), searches: s.count, downloads: dl?.count || 0 };
    });

    return (
        <>
            <div className="page-header">
                <div className="page-header-text">
                    <h2>Dashboard Overview</h2>
                    <p>Real-time overview of your MovieHub backend</p>
                </div>
                <div className="page-actions">
                    <button className="btn btn-sm" onClick={() => window.location.reload()}>
                        <RefreshCw size={14} /> Refresh
                    </button>
                </div>
            </div>

            <div className="stats-grid">
                {cards.map((c) => (
                    <div className="stat-card" key={c.label}>
                        <div className="stat-header">
                            <div>
                                <div className="stat-value" style={{ color: c.color }}>{c.value.toLocaleString()}</div>
                                <div className="stat-label">{c.label}</div>
                            </div>
                            <div className="stat-icon" style={{ background: c.bg }}>
                                <c.icon size={20} color={c.color} />
                            </div>
                        </div>
                    </div>
                ))}
            </div>

            {chartData.length > 0 && (
                <div className="card">
                    <div className="card-header">
                        <div>
                            <h3>Last 7 Days Activity</h3>
                            <div className="card-subtitle">Interaction data across all movie sources</div>
                        </div>
                    </div>
                    <ResponsiveContainer width="100%" height={280}>
                        <AreaChart data={chartData}>
                            <defs>
                                <linearGradient id="searchGrad" x1="0" y1="0" x2="0" y2="1">
                                    <stop offset="5%" stopColor="var(--blue)" stopOpacity={0.3} />
                                    <stop offset="95%" stopColor="var(--blue)" stopOpacity={0} />
                                </linearGradient>
                                <linearGradient id="dlGrad" x1="0" y1="0" x2="0" y2="1">
                                    <stop offset="5%" stopColor="var(--green)" stopOpacity={0.3} />
                                    <stop offset="95%" stopColor="var(--green)" stopOpacity={0} />
                                </linearGradient>
                            </defs>
                            <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.04)" />
                            <XAxis dataKey="date" stroke="var(--text-muted)" fontSize={12} tickLine={false} axisLine={false} />
                            <YAxis stroke="var(--text-muted)" fontSize={12} tickLine={false} axisLine={false} />
                            <Tooltip
                                contentStyle={{ background: 'var(--bg-card)', border: '1px solid var(--border-light)', borderRadius: 8, boxShadow: '0 8px 32px rgba(0,0,0,0.4)' }}
                                labelStyle={{ color: 'var(--text-primary)', fontWeight: 600 }}
                            />
                            <Area type="monotone" dataKey="searches" stroke="var(--blue)" strokeWidth={2} fill="url(#searchGrad)" dot={{ r: 3, fill: 'var(--blue)' }} />
                            <Area type="monotone" dataKey="downloads" stroke="var(--green)" strokeWidth={2} fill="url(#dlGrad)" dot={{ r: 3, fill: 'var(--green)' }} />
                        </AreaChart>
                    </ResponsiveContainer>
                </div>
            )}

            <div className="grid-2">
                <div className="card">
                    <div className="card-header"><h3>🔥 Top Downloads</h3></div>
                    {stats?.top_downloads?.length ? (
                        <div>
                            {stats.top_downloads.slice(0, 5).map((d, i) => (
                                <div className="trending-item" key={i}>
                                    <div className="trending-rank">{i + 1}</div>
                                    <div className="trending-info">
                                        <div className="trending-title">{d.movie_title}</div>
                                    </div>
                                    <div className="trending-count">{d.count.toLocaleString()}</div>
                                </div>
                            ))}
                        </div>
                    ) : <div className="empty-state">No downloads yet</div>}
                </div>

                <div className="card">
                    <div className="card-header"><h3>🔍 Trending Searches</h3></div>
                    {stats?.top_searches?.length ? (
                        <div>
                            {stats.top_searches.slice(0, 5).map((s, i) => (
                                <div className="trending-item" key={i}>
                                    <div className="trending-rank">{i + 1}</div>
                                    <div className="trending-info">
                                        <div className="trending-title">{s.query}</div>
                                    </div>
                                    <div className="trending-count">{s.count.toLocaleString()}</div>
                                </div>
                            ))}
                        </div>
                    ) : <div className="empty-state">No searches yet</div>}
                </div>
            </div>

            {stats?.recent_errors?.length > 0 && (
                <div className="card">
                    <div className="card-header"><h3>⚠️ Recent Errors (24h)</h3></div>
                    <table className="data-table">
                        <thead><tr><th>Severity</th><th>Source</th><th>Message</th><th>Time</th></tr></thead>
                        <tbody>
                            {stats.recent_errors.map((e) => (
                                <tr key={e.id}>
                                    <td><span className={`badge badge-${e.severity === 'critical' ? 'red' : e.severity === 'warning' ? 'yellow' : 'blue'}`}>{e.severity}</span></td>
                                    <td>{e.source}</td>
                                    <td style={{ maxWidth: 300, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{e.message}</td>
                                    <td style={{ fontSize: 12, whiteSpace: 'nowrap' }}>{e.created_at?.slice(11, 19)}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            )}
        </>
    );
}

// ─── Movies / Manual Links Page ──────────────────────────────────────

function MoviesPage() {
    const [links, setLinks] = useState([]);
    const [total, setTotal] = useState(0);
    const [search, setSearch] = useState('');
    const [loading, setLoading] = useState(true);
    const [showAdd, setShowAdd] = useState(false);
    const [page, setPage] = useState(1);
    const limit = 12;

    const fetchLinks = useCallback(async () => {
        setLoading(true);
        try {
            const res = await api.get('/admin/manual-links', { params: { search, limit, page } });
            setLinks(res.data.links || []);
            setTotal(res.data.total || 0);
        } catch { /* ignore */ }
        setLoading(false);
    }, [search, page]);

    useEffect(() => { fetchLinks(); }, [fetchLinks]);

    const deleteLink = async (id) => {
        if (!confirm('Delete this link?')) return;
        await api.delete(`/admin/manual-links/${id}`);
        fetchLinks();
    };

    const totalPages = Math.ceil(total / limit);

    return (
        <>
            <div className="page-header">
                <div className="page-header-text">
                    <h2>Movies</h2>
                    <p>Manage your professional film library and catalog assets.</p>
                </div>
                <div className="page-actions">
                    <button className="btn btn-primary" onClick={() => setShowAdd(true)}>
                        <Plus size={16} /> Add Movie
                    </button>
                </div>
            </div>

            <div className="filter-bar">
                <div className="search-bar">
                    <Search size={16} className="search-icon" />
                    <input placeholder="Search movies..." value={search} onChange={(e) => { setSearch(e.target.value); setPage(1); }} />
                </div>
                <span style={{ fontSize: 13, color: 'var(--text-muted)', marginLeft: 'auto' }}>
                    Showing {links.length} of {total} results
                </span>
            </div>

            {loading ? <div className="loading-spinner"><div className="spinner" /></div> : (
                <>
                    {links.length ? (
                        <div className="movie-grid">
                            {links.map((l) => (
                                <div className="movie-card" key={l.id}>
                                    <div className="movie-card-body">
                                        {l.movie_poster_url ? (
                                            <img className="movie-card-poster" src={l.movie_poster_url.startsWith('http') ? l.movie_poster_url : `https://image.tmdb.org/t/p/w200${l.movie_poster_url}`} alt="" />
                                        ) : (
                                            <div className="movie-card-poster" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                                <Film size={24} color="var(--text-muted)" />
                                            </div>
                                        )}
                                        <div className="movie-card-info">
                                            <div className="movie-card-title">{l.movie_title}</div>
                                            <div className="movie-card-year">
                                                {l.movie_year && `${l.movie_year} · `}
                                                <span className="badge badge-blue" style={{ fontSize: 10 }}>{l.source_name}</span>
                                            </div>
                                            <div className="movie-card-desc" style={{ marginTop: 6 }}>
                                                Priority: <strong style={{ color: 'var(--accent-light)' }}>{l.priority}</strong>
                                                {' · '}Status: <span className={l.status === 'active' ? '' : ''} style={{ color: l.status === 'active' ? 'var(--green)' : 'var(--red)' }}>{l.status}</span>
                                            </div>
                                        </div>
                                    </div>
                                    <div className="movie-card-footer">
                                        <a href={l.source_url} target="_blank" rel="noreferrer" style={{ fontSize: 12, color: 'var(--text-muted)', maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', display: 'block' }}>
                                            {l.source_url}
                                        </a>
                                        <button className="btn btn-danger btn-sm" onClick={() => deleteLink(l.id)}>
                                            <Trash2 size={14} />
                                        </button>
                                    </div>
                                </div>
                            ))}
                        </div>
                    ) : (
                        <div className="card">
                            <div className="empty-state">
                                <Film size={40} />
                                <p>No movies found. Add your first movie to get started!</p>
                            </div>
                        </div>
                    )}

                    {totalPages > 1 && (
                        <div className="pagination">
                            <button className="pagination-btn" disabled={page <= 1} onClick={() => setPage(page - 1)}>
                                <ChevronLeft size={16} />
                            </button>
                            {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => {
                                const p = i + 1;
                                return (
                                    <button key={p} className={`pagination-btn ${page === p ? 'active' : ''}`} onClick={() => setPage(p)}>
                                        {p}
                                    </button>
                                );
                            })}
                            <span className="pagination-info">of {totalPages}</span>
                            <button className="pagination-btn" disabled={page >= totalPages} onClick={() => setPage(page + 1)}>
                                <ChevronRight size={16} />
                            </button>
                        </div>
                    )}
                </>
            )}

            {showAdd && <AddMovieModal onClose={() => setShowAdd(false)} onSuccess={fetchLinks} />}
        </>
    );
}

// ─── Add Movie Modal (Multi-Step) ────────────────────────────────────

function AddMovieModal({ onClose, onSuccess }) {
    const [step, setStep] = useState(1);
    const [movieTitle, setMovieTitle] = useState('');
    const [tmdbId, setTmdbId] = useState('');
    const [year, setYear] = useState('');
    const [language, setLanguage] = useState('');
    const [links, setLinks] = useState([{ source_name: 'hdhub4u', source_url: '', priority: 1 }]);
    const [tmdbResults, setTmdbResults] = useState([]);
    const [saving, setSaving] = useState(false);
    const [searchLoading, setSearchLoading] = useState(false);

    const searchTmdb = async () => {
        if (!movieTitle) return;
        setSearchLoading(true);
        try {
            const res = await api.get('/admin/tmdb/search', { params: { query: movieTitle } });
            setTmdbResults(res.data.results?.slice(0, 6) || []);
        } catch { /* ignore */ }
        setSearchLoading(false);
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
            alert('Failed: ' + (err.response?.data?.detail || err.message));
        }
        setSaving(false);
    };

    const steps = ['Search', 'Details', 'Links'];

    return (
        <div className="modal-overlay" onClick={onClose}>
            <div className="modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 640 }}>
                <div className="modal-header">
                    <h3>Add Movie</h3>
                    <button className="btn btn-ghost btn-sm" onClick={onClose}><X size={18} /></button>
                </div>

                <div className="stepper">
                    {steps.map((s, i) => (
                        <span key={s} style={{ display: 'contents' }}>
                            <div className={`stepper-step ${step === i + 1 ? 'active' : step > i + 1 ? 'done' : ''}`}>
                                <div className="stepper-dot">{step > i + 1 ? <Check size={14} /> : i + 1}</div>
                                <span>{s}</span>
                            </div>
                            {i < steps.length - 1 && <div className={`stepper-line ${step > i + 1 ? 'done' : ''}`} />}
                        </span>
                    ))}
                </div>

                {step === 1 && (
                    <div>
                        <div className="form-group">
                            <label className="form-label">Search Movie</label>
                            <div style={{ display: 'flex', gap: 8 }}>
                                <input className="form-input" value={movieTitle} onChange={(e) => setMovieTitle(e.target.value)}
                                    placeholder="e.g. Inception" onKeyDown={(e) => e.key === 'Enter' && (e.preventDefault(), searchTmdb())} />
                                <button className="btn btn-primary" onClick={searchTmdb} disabled={searchLoading}>
                                    {searchLoading ? '...' : 'Search TMDB'}
                                </button>
                            </div>
                        </div>
                        {tmdbResults.length > 0 && (
                            <div style={{ background: 'var(--bg-primary)', border: '1px solid var(--border-light)', borderRadius: 8, maxHeight: 260, overflowY: 'auto' }}>
                                {tmdbResults.map((m) => (
                                    <div key={m.id} style={{ padding: '12px 16px', cursor: 'pointer', fontSize: 13, borderBottom: '1px solid var(--border)', display: 'flex', gap: 10, alignItems: 'center', transition: 'background 0.15s' }}
                                        onClick={() => selectTmdb(m)}
                                        onMouseEnter={(e) => e.currentTarget.style.background = 'var(--bg-hover)'}
                                        onMouseLeave={(e) => e.currentTarget.style.background = ''}>
                                        {m.poster_path ? (
                                            <img src={`https://image.tmdb.org/t/p/w92${m.poster_path}`} alt="" style={{ width: 36, height: 54, borderRadius: 4, objectFit: 'cover' }} />
                                        ) : (
                                            <div style={{ width: 36, height: 54, borderRadius: 4, background: 'var(--bg-hover)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                                <Film size={16} color="var(--text-muted)" />
                                            </div>
                                        )}
                                        <div>
                                            <strong>{m.title}</strong>
                                            <span style={{ color: 'var(--text-muted)', marginLeft: 6 }}>({m.release_date?.slice(0, 4)}) — ID: {m.id}</span>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}
                        <div className="modal-actions">
                            <button className="btn" onClick={onClose}>Cancel</button>
                            <button className="btn btn-primary" onClick={() => setStep(2)} disabled={!movieTitle}>Next</button>
                        </div>
                    </div>
                )}

                {step === 2 && (
                    <div>
                        <div className="grid-3">
                            <div className="form-group">
                                <label className="form-label">TMDB ID</label>
                                <input className="form-input" value={tmdbId} onChange={(e) => setTmdbId(e.target.value)} placeholder="Optional" />
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
                        <div className="form-group">
                            <label className="form-label">Movie Title</label>
                            <input className="form-input" value={movieTitle} onChange={(e) => setMovieTitle(e.target.value)} />
                        </div>
                        <div className="modal-actions">
                            <button className="btn" onClick={() => setStep(1)}><ChevronLeft size={14} /> Back</button>
                            <button className="btn btn-primary" onClick={() => setStep(3)}>Next</button>
                        </div>
                    </div>
                )}

                {step === 3 && (
                    <div>
                        <p style={{ fontSize: 13, color: 'var(--text-secondary)', marginBottom: 16 }}>Add source links for <strong style={{ color: 'var(--text-primary)' }}>{movieTitle}</strong></p>
                        {links.map((link, i) => (
                            <div key={i} style={{ display: 'flex', gap: 8, marginBottom: 10, alignItems: 'center' }}>
                                <select className="form-input" style={{ width: 140, flexShrink: 0 }} value={link.source_name}
                                    onChange={(e) => updateLink(i, 'source_name', e.target.value)}>
                                    <option value="hdhub4u">HDHub4u</option>
                                    <option value="skymovieshd">SkyMoviesHD</option>
                                    <option value="cinefreak">CinemaFreak</option>
                                    <option value="katmoviehd">KatMovieHD</option>
                                </select>
                                <input className="form-input" value={link.source_url} onChange={(e) => updateLink(i, 'source_url', e.target.value)}
                                    placeholder="https://..." style={{ flex: 1 }} />
                                <input className="form-input" type="number" value={link.priority} onChange={(e) => updateLink(i, 'priority', parseInt(e.target.value) || 1)}
                                    style={{ width: 70, flexShrink: 0 }} title="Priority" />
                                {links.length > 1 && <button className="btn btn-danger btn-sm" onClick={() => removeLink(i)}><X size={14} /></button>}
                            </div>
                        ))}
                        <button className="btn btn-sm" onClick={addLink} style={{ marginBottom: 8 }}><Plus size={14} /> Add another link</button>

                        <div className="modal-actions">
                            <button className="btn" onClick={() => setStep(2)}><ChevronLeft size={14} /> Back</button>
                            <button className="btn btn-primary" onClick={submit} disabled={saving}>{saving ? 'Saving...' : 'Save Movie'}</button>
                        </div>
                    </div>
                )}
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
                <div className="page-header-text">
                    <h2>Search Analytics</h2>
                    <p>What users are searching for — last 30 days</p>
                </div>
            </div>

            {data?.daily_searches?.length > 0 && (
                <div className="card">
                    <div className="card-header">
                        <div>
                            <h3>📈 Search Volume</h3>
                            <div className="card-subtitle">Daily search trend over the last 30 days</div>
                        </div>
                    </div>
                    <ResponsiveContainer width="100%" height={260}>
                        <AreaChart data={data.daily_searches.map((d) => ({ date: d.date?.slice(5), count: d.count }))}>
                            <defs>
                                <linearGradient id="searchArea" x1="0" y1="0" x2="0" y2="1">
                                    <stop offset="5%" stopColor="var(--blue)" stopOpacity={0.3} />
                                    <stop offset="95%" stopColor="var(--blue)" stopOpacity={0} />
                                </linearGradient>
                            </defs>
                            <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.04)" />
                            <XAxis dataKey="date" stroke="var(--text-muted)" fontSize={12} tickLine={false} axisLine={false} />
                            <YAxis stroke="var(--text-muted)" fontSize={12} tickLine={false} axisLine={false} />
                            <Tooltip contentStyle={{ background: 'var(--bg-card)', border: '1px solid var(--border-light)', borderRadius: 8 }} />
                            <Area type="monotone" dataKey="count" stroke="var(--blue)" strokeWidth={2} fill="url(#searchArea)" dot={{ r: 3, fill: 'var(--blue)' }} />
                        </AreaChart>
                    </ResponsiveContainer>
                </div>
            )}

            <div className="grid-2">
                <div className="card">
                    <div className="card-header"><h3>🔝 Top Queries</h3></div>
                    {data?.top_queries?.length ? (
                        <div>
                            {data.top_queries.slice(0, 12).map((q, i) => (
                                <div className="trending-item" key={i}>
                                    <div className="trending-rank">{i + 1}</div>
                                    <div className="trending-info">
                                        <div className="trending-title">{q.query}</div>
                                    </div>
                                    <div className="trending-count">{q.count}</div>
                                </div>
                            ))}
                        </div>
                    ) : <div className="empty-state">No searches recorded yet</div>}
                </div>

                <div className="card">
                    <div className="card-header"><h3>❌ Zero-Result Searches</h3></div>
                    {data?.zero_results?.length ? (
                        <div>
                            {data.zero_results.map((q, i) => (
                                <div className="trending-item" key={i}>
                                    <div className="trending-rank" style={{ background: 'var(--red-bg)', color: 'var(--red)' }}>{i + 1}</div>
                                    <div className="trending-info">
                                        <div className="trending-title">{q.query}</div>
                                    </div>
                                    <div className="trending-count" style={{ color: 'var(--red)' }}>{q.count}</div>
                                </div>
                            ))}
                        </div>
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

    const totalMovies = sources.reduce((a, s) => a + (s.total_movies || 0), 0);
    const avgLatency = sources.length ? (sources.reduce((a, s) => a + (s.avg_response_time_ms || 0), 0) / sources.length / 1000).toFixed(1) : 0;

    return (
        <>
            <div className="page-header">
                <div className="page-header-text">
                    <h2>Data Providers</h2>
                    <p>Manage real-time scraping and synchronization tasks from your primary movie data sources.</p>
                </div>
                <div className="page-actions">
                    <button className="btn btn-sm" onClick={fetchSources}><RefreshCw size={14} /> Refresh</button>
                </div>
            </div>

            <div className="summary-row">
                <div className="summary-item">
                    <Database size={18} color="var(--accent)" />
                    <div>
                        <div className="summary-item-label">Total Stored</div>
                        <div className="summary-item-value">{totalMovies.toLocaleString()}</div>
                    </div>
                </div>
                <div className="summary-item">
                    <Zap size={18} color="var(--yellow)" />
                    <div>
                        <div className="summary-item-label">Global Latency</div>
                        <div className="summary-item-value">{avgLatency}s</div>
                    </div>
                </div>
                <div className="summary-item">
                    <Activity size={18} color="var(--green)" />
                    <div>
                        <div className="summary-item-label">Active Sources</div>
                        <div className="summary-item-value">{sources.filter(s => s.is_enabled).length} / {sources.length}</div>
                    </div>
                </div>
            </div>

            <div className="stats-grid" style={{ gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))' }}>
                {sources.map((s) => (
                    <div className="source-card" key={s.source_name}>
                        <div className="source-card-header">
                            <div className="source-card-name">{s.source_name}</div>
                            <span className={`badge ${s.is_enabled ? 'badge-green' : 'badge-red'}`}>
                                {s.is_enabled ? 'Online' : 'Offline'}
                            </span>
                        </div>
                        <div className="source-stats">
                            <div className="source-stat">
                                <div className="source-stat-label">Total Movies</div>
                                <div className="source-stat-value">{(s.total_movies || 0).toLocaleString()}</div>
                            </div>
                            <div className="source-stat">
                                <div className="source-stat-label">Success Rate</div>
                                <div className="source-stat-value" style={{ color: (s.success_rate || 0) > 0.8 ? 'var(--green)' : (s.success_rate || 0) > 0.5 ? 'var(--yellow)' : 'var(--red)' }}>
                                    {((s.success_rate || 0) * 100).toFixed(1)}%
                                </div>
                            </div>
                            <div className="source-stat">
                                <div className="source-stat-label">Avg. Res</div>
                                <div className="source-stat-value">{s.avg_response_time_ms ? `${(s.avg_response_time_ms / 1000).toFixed(1)}s` : 'N/A'}</div>
                            </div>
                        </div>
                        <div className="progress-bar">
                            <div className="progress-bar-fill" style={{
                                width: `${(s.success_rate || 0) * 100}%`,
                                background: (s.success_rate || 0) > 0.8 ? 'var(--green)' : (s.success_rate || 0) > 0.5 ? 'var(--yellow)' : 'var(--red)',
                            }} />
                        </div>
                        <div className="source-actions">
                            <button className={`btn btn-sm ${s.is_enabled ? 'btn-danger' : 'btn-primary'}`}
                                onClick={() => toggle(s.source_name, s.is_enabled)}>
                                {s.is_enabled ? 'Disable' : 'Enable'}
                            </button>
                            {s.consecutive_failures > 0 && (
                                <span style={{ fontSize: 11, color: 'var(--red)', display: 'flex', alignItems: 'center', gap: 4, marginLeft: 'auto' }}>
                                    <AlertTriangle size={12} /> {s.consecutive_failures} failures
                                </span>
                            )}
                        </div>
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

    const severityConfig = {
        critical: { icon: '🔴', color: 'var(--red)' },
        warning: { icon: '🟡', color: 'var(--yellow)' },
        info: { icon: '🔵', color: 'var(--blue)' },
    };

    return (
        <>
            <div className="page-header">
                <div className="page-header-text">
                    <h2>System Error Logs</h2>
                    <p>Health Monitoring — {errors.length} events</p>
                </div>
                <div className="page-actions">
                    <button className="btn btn-sm" onClick={fetchErrors}><RefreshCw size={14} /> Refresh</button>
                </div>
            </div>

            <div className="filter-bar">
                {['', 'critical', 'warning', 'info'].map((f) => (
                    <button key={f} className={`filter-chip ${filter === f ? 'active' : ''}`}
                        onClick={() => setFilter(f)}>
                        {f ? `${severityConfig[f]?.icon || ''} ${f}` : 'All Events'}
                    </button>
                ))}
            </div>

            {errors.length ? (
                <div>
                    {errors.map((e) => (
                        <div className="error-card" key={e.id}>
                            <div className="error-card-header">
                                <span className={`badge badge-${e.severity === 'critical' ? 'red' : e.severity === 'warning' ? 'yellow' : 'blue'}`}>
                                    {e.severity}
                                </span>
                                <div className="error-card-message">{e.message}</div>
                            </div>
                            <div className="error-card-meta">
                                <span>Source: <strong style={{ color: 'var(--text-primary)' }}>{e.source}</strong></span>
                                {e.error_type && <span>Type: {e.error_type}</span>}
                                <span>{e.created_at?.slice(0, 16).replace('T', ' ')}</span>
                                <span style={{ marginLeft: 'auto' }}>
                                    {e.resolved ? (
                                        <span className="badge badge-green">Resolved</span>
                                    ) : (
                                        <span className="badge badge-yellow">Open</span>
                                    )}
                                </span>
                            </div>
                            {!e.resolved && (
                                <div className="error-card-actions">
                                    <button className="btn btn-sm" onClick={() => resolve(e.id)}>
                                        <Check size={14} /> Mark Resolved
                                    </button>
                                </div>
                            )}
                        </div>
                    ))}
                </div>
            ) : (
                <div className="card">
                    <div className="empty-state">
                        <Check size={40} color="var(--green)" />
                        <p>No errors — everything is running smoothly! 🎉</p>
                    </div>
                </div>
            )}
        </>
    );
}

// ─── Settings Page ───────────────────────────────────────────────────

function SettingsPage() {
    const [config, setConfig] = useState({});
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [edits, setEdits] = useState({});
    const [activeTab, setActiveTab] = useState('general');

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

    const tabs = [
        { id: 'general', label: 'General', icon: Settings },
        { id: 'security', label: 'Security', icon: Shield },
        { id: 'api', label: 'API Keys', icon: Key },
        { id: 'logs', label: 'Logs', icon: FileText },
    ];

    const booleanKeys = ['force_update', 'maintenance_mode'];
    const generalKeys = ['app_logo_url', 'splash_screen_url', 'app_version', 'sync_interval_hours', 'max_concurrent_scrapers', 'featured_movie_ids'];
    const securityKeys = ['force_update', 'maintenance_mode'];

    const renderToggle = (key) => (
        <div className="toggle-row" key={key}>
            <div>
                <div className="toggle-row-label">{key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}</div>
                <div className="toggle-row-desc">{config[key]?.description || ''}</div>
            </div>
            <label className="toggle">
                <input type="checkbox" checked={edits[key] === 'true'} onChange={(e) => setEdits({ ...edits, [key]: e.target.checked ? 'true' : 'false' })} />
                <span className="toggle-slider"></span>
            </label>
        </div>
    );

    const renderInput = (key) => (
        <div className="form-group" key={key}>
            <label className="form-label">{key.replace(/_/g, ' ')}</label>
            <input className="form-input" value={edits[key] || ''} onChange={(e) => setEdits({ ...edits, [key]: e.target.value })} />
            {config[key]?.description && <div className="form-hint">{config[key].description}</div>}
        </div>
    );

    return (
        <>
            <div className="page-header">
                <div className="page-header-text">
                    <h2>Configuration</h2>
                    <p>Manage global app identity, automation scrapers, and core system preferences.</p>
                </div>
            </div>

            <div className="tabs">
                {tabs.map(t => (
                    <button key={t.id} className={`tab ${activeTab === t.id ? 'active' : ''}`} onClick={() => setActiveTab(t.id)}>
                        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
                            <t.icon size={14} /> {t.label}
                        </span>
                    </button>
                ))}
            </div>

            {activeTab === 'general' && (
                <div>
                    <div className="settings-section">
                        <div className="settings-section-title">App Identity</div>
                        <div className="settings-section-desc">Configure your application branding and version.</div>
                        <div className="card">
                            {['app_logo_url', 'splash_screen_url', 'app_version'].filter(k => config[k]).map(renderInput)}
                        </div>
                    </div>

                    <div className="settings-section">
                        <div className="settings-section-title">Scraper Configuration</div>
                        <div className="settings-section-desc">Configure concurrency and timing for web scrapers.</div>
                        <div className="card">
                            {['sync_interval_hours', 'max_concurrent_scrapers'].filter(k => config[k]).map(renderInput)}
                            <div className="form-hint" style={{ marginTop: -8, marginBottom: 8 }}>
                                ⚠️ Increasing concurrent scrapers may speed up updates but can lead to IP blocks from metadata providers.
                            </div>
                        </div>
                    </div>

                    <div className="settings-section">
                        <div className="settings-section-title">Feature Toggles</div>
                        <div className="settings-section-desc">Enable or disable app-wide features.</div>
                        <div className="card">
                            {['featured_movie_ids'].filter(k => config[k]).map(renderInput)}
                        </div>
                    </div>
                </div>
            )}

            {activeTab === 'security' && (
                <div>
                    <div className="settings-section">
                        <div className="settings-section-title">Version Control</div>
                        <div className="settings-section-desc">Control app update behavior and maintenance mode.</div>
                        <div className="card">
                            {securityKeys.filter(k => config[k]).map(renderToggle)}
                        </div>
                    </div>

                    <div className="settings-section">
                        <div className="danger-zone">
                            <h4>⚠️ Danger Zone</h4>
                            <p>Resetting settings will restore all configurations to their default factory states. This action cannot be undone.</p>
                            <button className="btn btn-danger">Reset All Settings</button>
                        </div>
                    </div>
                </div>
            )}

            {activeTab === 'api' && (
                <div className="card">
                    <div className="empty-state">
                        <Key size={40} />
                        <p>API key management coming soon.</p>
                    </div>
                </div>
            )}

            {activeTab === 'logs' && (
                <div className="card">
                    <div className="empty-state">
                        <FileText size={40} />
                        <p>System logs viewer coming soon.</p>
                    </div>
                </div>
            )}

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginTop: 24 }}>
                <button className="btn btn-primary btn-lg" onClick={save} disabled={saving}>
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
                    <Route path="/movies" element={<MoviesPage />} />
                    <Route path="/manual-links" element={<MoviesPage />} />
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
