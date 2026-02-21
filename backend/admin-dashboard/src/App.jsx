import { useState, useEffect, useCallback } from 'react';
import { HashRouter, Routes, Route, Navigate } from 'react-router-dom';
import api from './api';
import './index.css';

import Sidebar from './components/Sidebar';
import Header from './components/Header';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import MoviesPage from './pages/MoviesPage';
import SearchPage from './pages/SearchPage';
import SourcesPage from './pages/SourcesPage';
import ErrorsPage from './pages/ErrorsPage';
import SettingsPage from './pages/SettingsPage';

function useAuth() {
    const [user, setUser] = useState(() => {
        try { return JSON.parse(localStorage.getItem('admin_user')); } catch { return null; }
    });

    const login = useCallback((userData) => setUser(userData), []);
    const logout = useCallback(() => {
        localStorage.removeItem('admin_token');
        localStorage.removeItem('admin_user');
        setUser(null);
    }, []);

    return { user, login, logout };
}

function AuthenticatedApp({ user, logout }) {
    return (
        <div className="app-layout">
            <Sidebar user={user} onLogout={logout} />
            <main className="main-content">
                <Header user={user} />
                <Routes>
                    <Route path="/" element={<DashboardPage />} />
                    <Route path="/movies" element={<MoviesPage />} />
                    <Route path="/search" element={<SearchPage />} />
                    <Route path="/sources" element={<SourcesPage />} />
                    <Route path="/errors" element={<ErrorsPage />} />
                    <Route path="/settings" element={<SettingsPage />} />
                    <Route path="*" element={<Navigate to="/" replace />} />
                </Routes>
            </main>
        </div>
    );
}

export default function App() {
    const { user, login, logout } = useAuth();

    return (
        <HashRouter>
            <Routes>
                <Route path="/login" element={user ? <Navigate to="/" replace /> : <LoginPage onLogin={login} />} />
                <Route path="/*" element={user ? <AuthenticatedApp user={user} logout={logout} /> : <Navigate to="/login" replace />} />
            </Routes>
        </HashRouter>
    );
}
