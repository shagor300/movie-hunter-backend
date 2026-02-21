import { useLocation } from 'react-router-dom';

const pageTitles = {
    '/': { title: 'Dashboard', breadcrumb: 'Overview', label: '' },
    '/movies': { title: 'Movies', breadcrumb: 'Media Management', label: '' },
    '/search': { title: 'Search Insights', breadcrumb: 'Search Analytics', label: '' },
    '/sources': { title: 'Sources', breadcrumb: 'Source Management', label: '' },
    '/errors': { title: 'System Error Logs', breadcrumb: 'Health Monitoring', label: '' },
    '/settings': { title: 'Configuration', breadcrumb: 'Application Settings', label: '' },
};

export default function Header({ user }) {
    const location = useLocation();
    const page = pageTitles[location.pathname] || pageTitles['/'];

    return (
        <header className="top-header">
            <div>
                <div className="header-breadcrumb">
                    <span>Dashboard</span>
                    <span className="material-symbols-outlined" style={{ fontSize: 10 }}>chevron_right</span>
                    <span className="active">{page.breadcrumb}</span>
                </div>
                <div className="header-title">{page.title}</div>
            </div>
            <div className="header-right">
                <div className="header-search">
                    <span className="material-symbols-outlined">search</span>
                    <input type="text" placeholder="Search..." />
                </div>
                <button className="icon-btn">
                    <span className="material-symbols-outlined">notifications</span>
                    <span className="badge-dot"></span>
                </button>
                <div className="header-user">
                    <div className="header-user-text">
                        <div className="header-user-name">{user?.username || 'Admin'}</div>
                        <div className="header-user-role">System Admin</div>
                    </div>
                    <div className="header-user-avatar">
                        {(user?.username || 'A').charAt(0).toUpperCase()}
                    </div>
                </div>
            </div>
        </header>
    );
}
