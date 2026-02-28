import { useState, useEffect } from 'react';
import api from '../api';

export default function NotificationsPage() {
    const [history, setHistory] = useState([]);
    const [loading, setLoading] = useState(true);
    const [sending, setSending] = useState(false);
    const [msg, setMsg] = useState({ text: '', type: '' });

    // Compose form
    const [title, setTitle] = useState('');
    const [message, setMessage] = useState('');
    const [target, setTarget] = useState('all');

    const fetchHistory = async () => {
        setLoading(true);
        try {
            const { data } = await api.get('/admin/notifications');
            setHistory(Array.isArray(data) ? data : data.notifications || []);
        } catch { setHistory([]); }
        finally { setLoading(false); }
    };

    useEffect(() => { fetchHistory(); }, []);

    const sendNotification = async () => {
        if (!title.trim() || !message.trim()) {
            setMsg({ text: 'Title and message are required', type: 'error' });
            return;
        }
        setSending(true);
        setMsg({ text: '', type: '' });
        try {
            await api.post('/admin/notifications/send', { title, message, target });
            setMsg({ text: '✅ Notification sent successfully!', type: 'success' });
            setTitle(''); setMessage('');
            setTimeout(() => setMsg({ text: '', type: '' }), 4000);
            fetchHistory();
        } catch (err) {
            setMsg({ text: err.response?.data?.detail || 'Failed to send', type: 'error' });
        } finally { setSending(false); }
    };

    const templates = [
        { icon: '🎬', title: 'New Movie Added', message: 'A new movie has been added to FlixHub! Check it out now.' },
        { icon: '🔥', title: 'Trending Now', message: 'See what\'s trending this week on FlixHub!' },
        { icon: '🔧', title: 'Maintenance Notice', message: 'FlixHub will undergo scheduled maintenance. Thank you for your patience.' },
        { icon: '🎉', title: 'Feature Update', message: 'We\'ve added exciting new features! Update the app to try them out.' },
    ];

    return (
        <div className="page-scroll">
            <div className="page-header">
                <div className="page-header-text">
                    <div className="page-label">Firebase Cloud Messaging</div>
                    <h2>Push Notifications</h2>
                    <p>Compose and send push notifications to your users</p>
                </div>
            </div>

            <div className="grid-2">
                {/* Compose Card */}
                <div className="glass-card settings-card">
                    <div className="settings-card-header">
                        <span className="material-symbols-outlined">edit_notifications</span>
                        <h4>Compose Notification</h4>
                    </div>

                    {/* Quick Templates */}
                    <div style={{ marginBottom: 16 }}>
                        <div style={{ fontSize: 11, fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: 1, marginBottom: 8 }}>Quick Templates</div>
                        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                            {templates.map((t, i) => (
                                <button
                                    key={i}
                                    onClick={() => { setTitle(t.title); setMessage(t.message); }}
                                    style={{
                                        padding: '6px 12px',
                                        borderRadius: 8,
                                        border: '1px solid var(--border)',
                                        background: 'rgba(255,255,255,0.03)',
                                        color: 'var(--text-secondary)',
                                        fontSize: 12,
                                        fontWeight: 500,
                                        cursor: 'pointer',
                                        display: 'flex',
                                        alignItems: 'center',
                                        gap: 6,
                                    }}
                                >
                                    <span>{t.icon}</span> {t.title}
                                </button>
                            ))}
                        </div>
                    </div>

                    <div className="form-group">
                        <label className="form-label">Title</label>
                        <input
                            className="form-input"
                            type="text"
                            placeholder="Notification title..."
                            value={title}
                            onChange={e => setTitle(e.target.value)}
                        />
                    </div>
                    <div className="form-group">
                        <label className="form-label">Message Body</label>
                        <textarea
                            className="form-input"
                            rows="4"
                            placeholder="Type your notification message..."
                            value={message}
                            onChange={e => setMessage(e.target.value)}
                            style={{ resize: 'vertical', minHeight: 100, fontFamily: 'Inter, sans-serif', lineHeight: 1.6 }}
                        />
                    </div>
                    <div className="form-group">
                        <label className="form-label">Target Audience</label>
                        <select className="form-input" value={target} onChange={e => setTarget(e.target.value)}>
                            <option value="all">All Users</option>
                            <option value="android">Android Only</option>
                            <option value="active">Active Users (7 days)</option>
                        </select>
                        <div className="form-hint">Choose who receives this notification</div>
                    </div>

                    {/* Preview */}
                    {(title || message) && (
                        <div style={{ marginTop: 12 }}>
                            <div style={{ fontSize: 11, fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: 1, marginBottom: 8 }}>Preview</div>
                            <div style={{
                                background: 'rgba(255,255,255,0.04)',
                                borderRadius: 14,
                                padding: 16,
                                border: '1px solid var(--border)',
                                display: 'flex',
                                gap: 12,
                                alignItems: 'flex-start',
                            }}>
                                <div style={{
                                    width: 40, height: 40, borderRadius: 10,
                                    background: 'var(--primary-dim)',
                                    display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                                }}>
                                    <span className="material-symbols-outlined" style={{ color: 'var(--primary)', fontSize: 20 }}>notifications</span>
                                </div>
                                <div>
                                    <div style={{ fontWeight: 700, fontSize: 14 }}>{title || 'Notification Title'}</div>
                                    <div style={{ fontSize: 13, color: 'var(--text-secondary)', marginTop: 4, lineHeight: 1.5 }}>{message || 'Message body...'}</div>
                                    <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 6 }}>FlixHub • just now</div>
                                </div>
                            </div>
                        </div>
                    )}

                    {msg.text && (
                        <div style={{ marginTop: 16, padding: '10px 16px', borderRadius: 10, background: msg.type === 'success' ? 'rgba(0,229,160,0.08)' : 'rgba(239,68,68,0.08)', border: `1px solid ${msg.type === 'success' ? 'rgba(0,229,160,0.2)' : 'rgba(239,68,68,0.2)'}` }}>
                            <span style={{ fontSize: 13, fontWeight: 600, color: msg.type === 'success' ? '#00e5a0' : '#ef4444' }}>{msg.text}</span>
                        </div>
                    )}

                    <button
                        className="btn btn-primary"
                        style={{ width: '100%', marginTop: 20, height: 44, fontSize: 14, fontWeight: 700 }}
                        onClick={sendNotification}
                        disabled={sending || !title.trim() || !message.trim()}
                    >
                        <span className="material-symbols-outlined">{sending ? 'autorenew' : 'send'}</span>
                        {sending ? 'Sending...' : 'Send Notification'}
                    </button>
                </div>

                {/* History Card */}
                <div className="glass-card settings-card">
                    <div className="settings-card-header">
                        <span className="material-symbols-outlined">history</span>
                        <h4>Notification History</h4>
                    </div>

                    <div style={{ maxHeight: 520, overflowY: 'auto' }}>
                        {loading ? (
                            <div style={{ textAlign: 'center', padding: 40, color: 'var(--text-muted)' }}>
                                <span className="material-symbols-outlined" style={{ fontSize: 32, animation: 'spin 1s linear infinite' }}>autorenew</span>
                                <div style={{ marginTop: 8 }}>Loading history...</div>
                            </div>
                        ) : history.length === 0 ? (
                            <div style={{ textAlign: 'center', padding: 40, color: 'var(--text-muted)' }}>
                                <span className="material-symbols-outlined" style={{ fontSize: 40 }}>notifications_off</span>
                                <div style={{ marginTop: 8 }}>No notifications sent yet</div>
                            </div>
                        ) : history.map((n, i) => (
                            <div
                                key={n.id || i}
                                style={{
                                    padding: '14px 0',
                                    borderBottom: i < history.length - 1 ? '1px solid var(--border)' : 'none',
                                    display: 'flex',
                                    gap: 12,
                                    alignItems: 'flex-start',
                                }}
                            >
                                <div style={{
                                    width: 36, height: 36, borderRadius: 10, flexShrink: 0,
                                    background: 'var(--primary-dim)',
                                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                                }}>
                                    <span className="material-symbols-outlined" style={{ color: 'var(--primary)', fontSize: 18 }}>
                                        {n.target_type === 'all' ? 'groups' : 'person'}
                                    </span>
                                </div>
                                <div style={{ flex: 1, minWidth: 0 }}>
                                    <div style={{ fontWeight: 700, fontSize: 13 }}>{n.title}</div>
                                    <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginTop: 2, lineHeight: 1.4 }}>{n.message}</div>
                                    <div style={{ display: 'flex', gap: 12, marginTop: 6 }}>
                                        <span style={{ fontSize: 11, color: 'var(--text-muted)' }}>
                                            {n.sent_at ? new Date(n.sent_at).toLocaleString() : '—'}
                                        </span>
                                        <span style={{
                                            fontSize: 10, fontWeight: 700, textTransform: 'uppercase',
                                            padding: '2px 8px', borderRadius: 6,
                                            background: 'rgba(105,97,255,0.1)', color: 'var(--primary)',
                                        }}>
                                            {n.target_type || 'all'}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );
}
