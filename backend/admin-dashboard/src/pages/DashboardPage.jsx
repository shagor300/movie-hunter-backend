import { useState, useEffect } from 'react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import api from '../api';

export default function DashboardPage() {
    const [stats, setStats] = useState(null);

    useEffect(() => {
        api.get('/admin/dashboard').then(r => setStats(r.data)).catch(() => { });
    }, []);

    const chartData = stats?.recent_searches?.map((item, i) => ({
        name: item.date || `Day ${i + 1}`,
        searches: item.count || 0,
    })) || Array.from({ length: 14 }, (_, i) => ({ name: `Day ${i + 1}`, searches: Math.floor(Math.random() * 500) + 100 }));

    const statCards = [
        { icon: 'video_library', label: 'Total Movies', value: stats?.total_movies ?? '—', trend: '+5.2%', up: true },
        { icon: 'search', label: "Today's Searches", value: stats?.today_searches ?? '—', trend: '+12%', up: true },
        { icon: 'download', label: 'Downloads', value: stats?.total_downloads ?? '—', trend: '+8.1%', up: true },
        { icon: 'dns', label: 'Active Sources', value: stats?.active_sources ?? '—', trend: 'Live', up: true },
    ];

    return (
        <div className="page-scroll">
            <div className="page-header">
                <div className="page-header-text">
                    <div className="page-label">Overview</div>
                    <h2>Dashboard</h2>
                    <p>Real-time metrics and system health overview</p>
                </div>
            </div>

            <div className="stats-grid">
                {statCards.map((card, i) => (
                    <div key={i} className="glass-card stat-card">
                        <div className="stat-header">
                            <div className="stat-icon">
                                <span className="material-symbols-outlined">{card.icon}</span>
                            </div>
                            <span className={`stat-trend ${card.up ? 'up' : 'down'}`}>
                                <span className="material-symbols-outlined">trending_up</span>
                                {card.trend}
                            </span>
                        </div>
                        <div className="stat-label">{card.label}</div>
                        <div className="stat-value">{typeof card.value === 'number' ? card.value.toLocaleString() : card.value}</div>
                    </div>
                ))}
            </div>

            <div className="glass-card chart-card">
                <div className="chart-card-header">
                    <div>
                        <h4>Search Activity</h4>
                        <p>Search volume over the last 30 days</p>
                    </div>
                </div>
                <div style={{ height: 320 }}>
                    <ResponsiveContainer width="100%" height="100%">
                        <AreaChart data={chartData}>
                            <defs>
                                <linearGradient id="colorSearches" x1="0" y1="0" x2="0" y2="1">
                                    <stop offset="5%" stopColor="#6961ff" stopOpacity={0.3} />
                                    <stop offset="95%" stopColor="#6961ff" stopOpacity={0} />
                                </linearGradient>
                            </defs>
                            <CartesianGrid strokeDasharray="3 3" />
                            <XAxis dataKey="name" tick={{ fontSize: 11 }} />
                            <YAxis tick={{ fontSize: 11 }} />
                            <Tooltip
                                contentStyle={{
                                    background: 'rgba(22, 33, 62, 0.95)',
                                    border: '1px solid rgba(255,255,255,0.1)',
                                    borderRadius: 8,
                                    color: '#f1f5f9',
                                    fontSize: 13,
                                }}
                            />
                            <Area type="monotone" dataKey="searches" stroke="#6961ff" strokeWidth={2} fill="url(#colorSearches)" />
                        </AreaChart>
                    </ResponsiveContainer>
                </div>
            </div>

            {stats?.top_searches?.length > 0 && (
                <div className="grid-2" style={{ marginTop: 32 }}>
                    <div className="glass-card" style={{ overflow: 'hidden' }}>
                        <div style={{ padding: '20px 24px', borderBottom: '1px solid rgba(255,255,255,0.08)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                            <h4 style={{ fontSize: 18, fontWeight: 700 }}>Top Searches</h4>
                        </div>
                        <table className="data-table">
                            <thead>
                                <tr>
                                    <th>Rank</th>
                                    <th>Query</th>
                                    <th style={{ textAlign: 'right' }}>Count</th>
                                </tr>
                            </thead>
                            <tbody>
                                {stats.top_searches.slice(0, 5).map((s, i) => (
                                    <tr key={i}>
                                        <td style={{ fontWeight: 700, color: 'var(--text-muted)' }}>#{String(i + 1).padStart(2, '0')}</td>
                                        <td style={{ fontWeight: 600 }}>{s.query}</td>
                                        <td style={{ textAlign: 'right', fontFamily: 'monospace' }}>{(s.count || 0).toLocaleString()}</td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>

                    <div className="glass-card" style={{ overflow: 'hidden' }}>
                        <div style={{ padding: '20px 24px', borderBottom: '1px solid rgba(255,255,255,0.08)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                            <h4 style={{ fontSize: 18, fontWeight: 700 }}>Trending</h4>
                        </div>
                        <table className="data-table">
                            <thead>
                                <tr>
                                    <th>Query</th>
                                    <th style={{ textAlign: 'right' }}>Searches</th>
                                </tr>
                            </thead>
                            <tbody>
                                {(stats.trending_searches || stats.top_searches || []).slice(0, 5).map((s, i) => (
                                    <tr key={i}>
                                        <td style={{ fontWeight: 600 }}>{s.query}</td>
                                        <td style={{ textAlign: 'right', fontFamily: 'monospace' }}>{(s.count || 0).toLocaleString()}</td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                </div>
            )}
        </div>
    );
}
