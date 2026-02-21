import { useLocation, useNavigate } from 'react-router-dom';

const navItems = [
    { path: '/', icon: 'dashboard', label: 'Dashboard' },
    { path: '/movies', icon: 'movie_filter', label: 'Movies' },
    { path: '/search', icon: 'analytics', label: 'Analytics' },
    { path: '/sources', icon: 'dns', label: 'Sources' },
    { path: '/errors', icon: 'terminal', label: 'Error Logs' },
    { path: '/settings', icon: 'settings', label: 'Settings' },
];

export default function Sidebar({ user, onLogout }) {
    const location = useLocation();
    const navigate = useNavigate();

    return (
        <aside className="sidebar">
            <div className="sidebar-brand">
                <div className="sidebar-brand-icon">
                    <span className="material-symbols-outlined">movie_filter</span>
                </div>
                <div>
                    <div className="sidebar-brand-name">MovieHub</div>
                    <div className="sidebar-brand-subtitle">Super Admin Console</div>
                </div>
            </div>

            <div className="sidebar-section-label">Navigation</div>

            <nav className="sidebar-nav">
                {navItems.map(item => (
                    <button
                        key={item.path}
                        className={`nav-item ${location.pathname === item.path ? 'active' : ''}`}
                        onClick={() => navigate(item.path)}
                    >
                        <span className="material-symbols-outlined">{item.icon}</span>
                        <span>{item.label}</span>
                    </button>
                ))}
            </nav>

            <div className="sidebar-footer">
                <div className="sidebar-user">
                    <div className="sidebar-avatar">
                        {(user?.username || 'A').charAt(0).toUpperCase()}
                    </div>
                    <div className="sidebar-user-info">
                        <div className="sidebar-user-name">{user?.username || 'Admin'}</div>
                        <div className="sidebar-user-role">System Admin</div>
                    </div>
                    <button className="logout-btn" onClick={onLogout} title="Logout">
                        <span className="material-symbols-outlined">logout</span>
                    </button>
                </div>
            </div>
        </aside>
    );
}
