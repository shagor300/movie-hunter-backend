import { useState, useEffect } from 'react';
import api from '../api';

export default function SearchPage() {
    const [analytics, setAnalytics] = useState(null);

    useEffect(() => {
        api.get('/admin/search-analytics').then(r => setAnalytics(r.data)).catch(() => { });
    }, []);

    const topSearches = analytics?.top_searches || [];
    const zeroResults = analytics?.zero_results || [];
    const totalSearches = analytics?.total_searches || 0;
    const avgPerDay = analytics?.avg_per_day || 0;

    const metricCards = [
        { label: 'Total Searches', value: totalSearches.toLocaleString(), trend: '+12.5%', up: true },
        { label: 'Avg. Searches/Day', value: avgPerDay.toLocaleString(), trend: '+5.2%', up: true },
        { label: 'Zero-Result Rate', value: zeroResults.length > 0 ? `${((zeroResults.length / Math.max(topSearches.length, 1)) * 100).toFixed(1)}%` : '0%', trend: '-0.8%', up: false },
    ];

    return (
        <div className="page-scroll">
            <div className="page-header">
                <div className="page-header-text">
                    <div className="page-label">Analytics</div>
                    <h2>Search Insights</h2>
                    <p>Understand what users are looking for</p>
                </div>
            </div>

            <div className="grid-3" style={{ marginBottom: 32 }}>
                {metricCards.map((card, i) => (
                    <div key={i} className="glass-card" style={{ padding: 24, position: 'relative', overflow: 'hidden' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                            <div>
                                <p style={{ color: 'var(--text-secondary)', fontSize: 14, fontWeight: 500 }}>{card.label}</p>
                                <h3 style={{ fontSize: 28, fontWeight: 700, marginTop: 4 }}>{card.value}</h3>
                            </div>
                            <span className={`badge ${card.up ? 'badge-green' : 'badge-amber'}`}>
                                <span className="material-symbols-outlined" style={{ fontSize: 12 }}>{card.up ? 'trending_up' : 'trending_down'}</span>
                                {card.trend}
                            </span>
                        </div>
                    </div>
                ))}
            </div>

            <div className="grid-2">
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
                            {topSearches.slice(0, 10).map((s, i) => (
                                <tr key={i}>
                                    <td style={{ fontWeight: 700, color: 'var(--text-muted)' }}>#{String(i + 1).padStart(2, '0')}</td>
                                    <td style={{ fontWeight: 600 }}>{s.query}</td>
                                    <td style={{ textAlign: 'right', fontFamily: 'monospace' }}>{(s.count || 0).toLocaleString()}</td>
                                </tr>
                            ))}
                            {topSearches.length === 0 && (
                                <tr><td colSpan={3} style={{ textAlign: 'center', padding: 32, color: 'var(--text-muted)' }}>No search data available</td></tr>
                            )}
                        </tbody>
                    </table>
                </div>

                <div className="glass-card" style={{ overflow: 'hidden', borderColor: 'rgba(245,158,11,0.2)' }}>
                    <div style={{ padding: '20px 24px', borderBottom: '1px solid rgba(255,255,255,0.08)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <div>
                            <h4 style={{ fontSize: 18, fontWeight: 700, display: 'flex', alignItems: 'center', gap: 8 }}>
                                Zero Result Queries
                                <span className="badge badge-amber">Content Gap</span>
                            </h4>
                            <p style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 4 }}>Movies requested but not found</p>
                        </div>
                    </div>
                    <table className="data-table">
                        <thead>
                            <tr>
                                <th>Query</th>
                                <th style={{ textAlign: 'right' }}>Misses</th>
                            </tr>
                        </thead>
                        <tbody>
                            {zeroResults.slice(0, 10).map((s, i) => (
                                <tr key={i}>
                                    <td style={{ fontWeight: 500 }}>{s.query}</td>
                                    <td style={{ textAlign: 'right', fontFamily: 'monospace', color: 'var(--amber)' }}>{(s.count || 0).toLocaleString()}</td>
                                </tr>
                            ))}
                            {zeroResults.length === 0 && (
                                <tr><td colSpan={2} style={{ textAlign: 'center', padding: 32, color: 'var(--text-muted)' }}>No zero-result queries</td></tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
}
