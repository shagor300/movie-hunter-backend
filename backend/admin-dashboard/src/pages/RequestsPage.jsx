import { useState, useEffect } from 'react';
import api from '../api';

export default function RequestsPage() {
    const [requests, setRequests] = useState([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState('all');
    const [search, setSearch] = useState('');

    const fetchRequests = async () => {
        setLoading(true);
        try {
            const { data } = await api.get('/admin/movie-requests', {
                params: { status: filter === 'all' ? undefined : filter, search: search || undefined },
            });
            setRequests(data.requests || []);
        } catch { setRequests([]); }
        finally { setLoading(false); }
    };

    useEffect(() => { fetchRequests(); }, [filter]);

    const updateStatus = async (id, status) => {
        try {
            await api.put(`/admin/movie-requests/${id}/status`, { status });
            fetchRequests();
        } catch { }
    };

    const deleteRequest = async (id) => {
        if (!confirm('Delete this request permanently?')) return;
        try {
            await api.delete(`/admin/movie-requests/${id}`);
            fetchRequests();
        } catch { }
    };

    const statusColors = {
        pending: { bg: 'rgba(251,191,36,0.1)', color: '#fbbf24', label: 'Pending' },
        approved: { bg: 'rgba(96,165,250,0.1)', color: '#60a5fa', label: 'Approved' },
        fulfilled: { bg: 'rgba(0,229,160,0.1)', color: '#00e5a0', label: 'Fulfilled' },
        rejected: { bg: 'rgba(239,68,68,0.1)', color: '#ef4444', label: 'Rejected' },
    };

    const stats = {
        total: requests.length,
        pending: requests.filter(r => r.status === 'pending').length,
        fulfilled: requests.filter(r => r.status === 'fulfilled').length,
        rejected: requests.filter(r => r.status === 'rejected').length,
    };

    const filtered = search
        ? requests.filter(r => r.movie_name?.toLowerCase().includes(search.toLowerCase()))
        : requests;

    return (
        <div className="page-scroll">
            <div className="page-header">
                <div className="page-header-text">
                    <div className="page-label">User Engagement</div>
                    <h2>Movie Requests</h2>
                    <p>View and manage movie requests submitted by users</p>
                </div>
            </div>

            {/* Stats Cards */}
            <div className="stats-grid" style={{ marginBottom: 24 }}>
                {[
                    { icon: 'inbox', label: 'Total', value: stats.total, color: 'var(--primary)' },
                    { icon: 'pending', label: 'Pending', value: stats.pending, color: '#fbbf24' },
                    { icon: 'check_circle', label: 'Fulfilled', value: stats.fulfilled, color: '#00e5a0' },
                    { icon: 'cancel', label: 'Rejected', value: stats.rejected, color: '#ef4444' },
                ].map((s, i) => (
                    <div key={i} className="glass-card stat-card">
                        <div className="stat-header">
                            <div className="stat-icon">
                                <span className="material-symbols-outlined" style={{ color: s.color }}>{s.icon}</span>
                            </div>
                        </div>
                        <div className="stat-label">{s.label}</div>
                        <div className="stat-value">{s.value}</div>
                    </div>
                ))}
            </div>

            {/* Filter Bar */}
            <div className="glass-card" style={{ display: 'flex', gap: 12, alignItems: 'center', padding: '12px 20px', marginBottom: 20 }}>
                <span className="material-symbols-outlined" style={{ color: 'var(--text-muted)', fontSize: 20 }}>filter_list</span>
                {['all', 'pending', 'approved', 'fulfilled', 'rejected'].map(f => (
                    <button
                        key={f}
                        onClick={() => setFilter(f)}
                        style={{
                            padding: '6px 16px',
                            borderRadius: 20,
                            border: filter === f ? '1px solid var(--primary)' : '1px solid var(--border)',
                            background: filter === f ? 'var(--primary-dim)' : 'transparent',
                            color: filter === f ? 'var(--primary)' : 'var(--text-secondary)',
                            fontSize: 13,
                            fontWeight: 600,
                            cursor: 'pointer',
                            textTransform: 'capitalize',
                        }}
                    >{f}</button>
                ))}
                <div style={{ flex: 1 }} />
                <input
                    type="text"
                    className="form-input"
                    placeholder="Search movies..."
                    value={search}
                    onChange={e => setSearch(e.target.value)}
                    onKeyDown={e => e.key === 'Enter' && fetchRequests()}
                    style={{ maxWidth: 250, height: 36, fontSize: 13 }}
                />
            </div>

            {/* Requests Table */}
            <div className="glass-card" style={{ overflow: 'hidden' }}>
                <table className="data-table">
                    <thead>
                        <tr>
                            <th style={{ width: 40 }}>#</th>
                            <th>Movie</th>
                            <th>Year</th>
                            <th>Language</th>
                            <th>Quality</th>
                            <th>Note</th>
                            <th>Status</th>
                            <th>Date</th>
                            <th style={{ textAlign: 'right' }}>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {loading ? (
                            <tr><td colSpan="9" style={{ textAlign: 'center', padding: 40, color: 'var(--text-muted)' }}>
                                <span className="material-symbols-outlined" style={{ fontSize: 32, animation: 'spin 1s linear infinite' }}>autorenew</span>
                                <div style={{ marginTop: 8 }}>Loading requests...</div>
                            </td></tr>
                        ) : filtered.length === 0 ? (
                            <tr><td colSpan="9" style={{ textAlign: 'center', padding: 40, color: 'var(--text-muted)' }}>
                                <span className="material-symbols-outlined" style={{ fontSize: 40 }}>inbox</span>
                                <div style={{ marginTop: 8 }}>No requests found</div>
                            </td></tr>
                        ) : filtered.map((req, i) => {
                            const st = statusColors[req.status] || statusColors.pending;
                            return (
                                <tr key={req.id}>
                                    <td style={{ fontWeight: 700, color: 'var(--text-muted)' }}>#{i + 1}</td>
                                    <td style={{ fontWeight: 600 }}>{req.movie_name}</td>
                                    <td>{req.year || '—'}</td>
                                    <td>{req.language || 'Any'}</td>
                                    <td>{req.quality || 'Any'}</td>
                                    <td style={{ maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                                        {req.note || '—'}
                                    </td>
                                    <td>
                                        <span style={{
                                            padding: '4px 12px',
                                            borderRadius: 12,
                                            fontSize: 11,
                                            fontWeight: 700,
                                            background: st.bg,
                                            color: st.color,
                                            textTransform: 'capitalize',
                                        }}>{st.label}</span>
                                    </td>
                                    <td style={{ fontSize: 12, color: 'var(--text-muted)' }}>
                                        {req.requested_at ? new Date(req.requested_at).toLocaleDateString() : '—'}
                                    </td>
                                    <td style={{ textAlign: 'right' }}>
                                        <div style={{ display: 'flex', gap: 4, justifyContent: 'flex-end' }}>
                                            {req.status === 'pending' && (
                                                <>
                                                    <button className="btn btn-sm" onClick={() => updateStatus(req.id, 'approved')}
                                                        style={{ background: 'rgba(96,165,250,0.1)', color: '#60a5fa', border: '1px solid rgba(96,165,250,0.2)' }}>
                                                        <span className="material-symbols-outlined" style={{ fontSize: 14 }}>thumb_up</span>
                                                    </button>
                                                    <button className="btn btn-sm" onClick={() => updateStatus(req.id, 'rejected')}
                                                        style={{ background: 'rgba(239,68,68,0.1)', color: '#ef4444', border: '1px solid rgba(239,68,68,0.2)' }}>
                                                        <span className="material-symbols-outlined" style={{ fontSize: 14 }}>thumb_down</span>
                                                    </button>
                                                </>
                                            )}
                                            {req.status === 'approved' && (
                                                <button className="btn btn-sm" onClick={() => updateStatus(req.id, 'fulfilled')}
                                                    style={{ background: 'rgba(0,229,160,0.1)', color: '#00e5a0', border: '1px solid rgba(0,229,160,0.2)' }}>
                                                    <span className="material-symbols-outlined" style={{ fontSize: 14 }}>done_all</span>
                                                </button>
                                            )}
                                            <button className="btn btn-sm" onClick={() => deleteRequest(req.id)}
                                                style={{ background: 'rgba(239,68,68,0.06)', color: '#ef4444', border: '1px solid rgba(239,68,68,0.1)' }}>
                                                <span className="material-symbols-outlined" style={{ fontSize: 14 }}>delete</span>
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            );
                        })}
                    </tbody>
                </table>
            </div>
        </div>
    );
}
