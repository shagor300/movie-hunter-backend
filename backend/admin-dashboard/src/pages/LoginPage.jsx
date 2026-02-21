import { useState } from 'react';
import api from '../api';

export default function LoginPage({ onLogin }) {
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);
        try {
            const { data } = await api.post('/admin/login', { username, password });
            localStorage.setItem('admin_token', data.token);
            localStorage.setItem('admin_user', JSON.stringify(data.user));
            onLogin(data.user);
        } catch (err) {
            setError(err.response?.data?.detail || 'Login failed');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="login-page">
            <div className="bg-glow-1" />
            <div className="bg-glow-2" />
            <div className="login-card">
                <div className="login-logo">
                    <div className="login-logo-icon">
                        <span className="material-symbols-outlined">movie_filter</span>
                    </div>
                    <h1>MovieHub</h1>
                    <p>Admin Console</p>
                </div>

                {error && (
                    <div className="login-error">
                        <span className="material-symbols-outlined" style={{ fontSize: 18 }}>error</span>
                        {error}
                    </div>
                )}

                <form className="login-form" onSubmit={handleSubmit}>
                    <div>
                        <label className="form-label">Username</label>
                        <div className="input-with-icon">
                            <span className="material-symbols-outlined">person</span>
                            <input
                                className="form-input"
                                type="text"
                                placeholder="Enter your username"
                                value={username}
                                onChange={e => setUsername(e.target.value)}
                                required
                            />
                        </div>
                    </div>
                    <div>
                        <label className="form-label">Password</label>
                        <div className="input-with-icon">
                            <span className="material-symbols-outlined">lock</span>
                            <input
                                className="form-input"
                                type="password"
                                placeholder="Enter your password"
                                value={password}
                                onChange={e => setPassword(e.target.value)}
                                required
                            />
                        </div>
                    </div>
                    <button className="login-btn" type="submit" disabled={loading}>
                        <span>{loading ? 'Signing in...' : 'Sign In'}</span>
                        <span className="material-symbols-outlined" style={{ fontSize: 20 }}>login</span>
                    </button>
                </form>

                <div className="login-footer">
                    <p>
                        <span className="material-symbols-outlined">shield</span>
                        Secured Admin Access Only
                    </p>
                </div>
            </div>
        </div>
    );
}
