import { useState, useEffect } from 'react';
import api from '../api';

export default function MoviesPage() {
    const [movies, setMovies] = useState([]);
    const [search, setSearch] = useState('');
    const [showModal, setShowModal] = useState(false);

    const load = () => api.get('/admin/manual-links').then(r => setMovies(r.data.links || [])).catch(() => { });
    useEffect(() => { load(); }, []);

    const deleteMovie = async (id) => {
        if (!confirm('Delete this movie?')) return;
        try { await api.delete(`/admin/manual-links/${id}`); load(); } catch { }
    };

    const filtered = movies.filter(m =>
        (m.title || '').toLowerCase().includes(search.toLowerCase()) ||
        String(m.tmdb_id || '').includes(search)
    );

    return (
        <div className="page-scroll">
            <div className="page-header">
                <div className="page-header-text">
                    <div className="page-label">Media Management</div>
                    <h2>Movies</h2>
                    <p>Manage your movie library — {movies.length} total entries</p>
                </div>
                <div className="page-actions">
                    <button className="btn-primary btn" onClick={() => setShowModal(true)}>
                        <span className="material-symbols-outlined">add</span>
                        Add Movie
                    </button>
                </div>
            </div>

            <div className="glass-card filter-bar" style={{ marginBottom: 24 }}>
                <div className="filter-search" style={{ flex: 1 }}>
                    <span className="material-symbols-outlined">search</span>
                    <input placeholder="Search movies by title or TMDB ID..." value={search} onChange={e => setSearch(e.target.value)} />
                </div>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                {filtered.map(movie => (
                    <div key={movie.id || movie.tmdb_id} className="glass-card movie-card">
                        <div className="movie-poster">
                            {movie.poster_url ? (
                                <img src={movie.poster_url} alt={movie.title} />
                            ) : (
                                <div style={{ width: '100%', height: '100%', background: 'var(--bg-panel)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                    <span className="material-symbols-outlined" style={{ fontSize: 48, color: 'var(--text-muted)' }}>movie</span>
                                </div>
                            )}
                        </div>
                        <div className="movie-details">
                            <div className="movie-title-row">
                                <h3>{movie.title} {movie.year ? `(${movie.year})` : ''}</h3>
                                <span className="badge badge-accent">TMDB {movie.tmdb_id}</span>
                            </div>
                            {movie.rating && (
                                <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 4 }}>
                                    <span className="material-symbols-outlined" style={{ color: 'var(--amber)', fontSize: 18 }}>star</span>
                                    <span style={{ fontWeight: 700, fontSize: 14 }}>{movie.rating}</span>
                                </div>
                            )}
                            <p className="movie-desc">{movie.overview || movie.description || 'No description available.'}</p>
                            <div className="movie-tags">
                                {(movie.genres || []).map((g, i) => <span key={i} className="movie-tag genre">{g}</span>)}
                                {(movie.sources || []).map((s, i) => <span key={i} className="movie-tag">{s}</span>)}
                            </div>
                        </div>
                        <div className="movie-actions">
                            <button className="movie-action-btn" title="Edit">
                                <span className="material-symbols-outlined">edit</span>
                            </button>
                            <button className="movie-action-btn danger" onClick={() => deleteMovie(movie.id || movie.tmdb_id)} title="Delete">
                                <span className="material-symbols-outlined">delete</span>
                            </button>
                            {movie.tmdb_id && (
                                <button className="movie-action-btn" onClick={() => window.open(`https://www.themoviedb.org/movie/${movie.tmdb_id}`, '_blank')} title="Open TMDB">
                                    <span className="material-symbols-outlined">open_in_new</span>
                                </button>
                            )}
                        </div>
                    </div>
                ))}
                {filtered.length === 0 && (
                    <div className="glass-card" style={{ padding: 64, textAlign: 'center' }}>
                        <span className="material-symbols-outlined" style={{ fontSize: 48, color: 'var(--text-muted)', marginBottom: 16 }}>movie_filter</span>
                        <h4 style={{ fontSize: 18, fontWeight: 700, marginBottom: 8 }}>No movies found</h4>
                        <p style={{ color: 'var(--text-secondary)' }}>Try adjusting your search or add a new movie.</p>
                    </div>
                )}
            </div>

            {showModal && <AddMovieModal onClose={() => setShowModal(false)} onSuccess={() => { setShowModal(false); load(); }} />}
        </div>
    );
}

function AddMovieModal({ onClose, onSuccess }) {
    const [tmdbId, setTmdbId] = useState('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        try {
            await api.post('/admin/manual-links', { movie_title: `TMDB-${tmdbId}`, tmdb_id: parseInt(tmdbId), links: [] });
            onSuccess();
        } catch (err) {
            setError(err.response?.data?.detail || 'Failed to add movie');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="modal-overlay" onClick={onClose}>
            <div className="modal" onClick={e => e.stopPropagation()}>
                <div className="modal-header">
                    <h3>Add Movie by TMDB ID</h3>
                    <button className="icon-btn" onClick={onClose}>
                        <span className="material-symbols-outlined">close</span>
                    </button>
                </div>
                <form onSubmit={handleSubmit}>
                    <div className="modal-body">
                        {error && <div className="login-error" style={{ marginBottom: 16 }}><span className="material-symbols-outlined" style={{ fontSize: 18 }}>error</span>{error}</div>}
                        <div className="form-group">
                            <label className="form-label">TMDB Movie ID</label>
                            <input className="form-input" type="number" placeholder="e.g. 27205" value={tmdbId} onChange={e => setTmdbId(e.target.value)} required />
                            <div className="form-hint">Enter the TMDB ID from themoviedb.org</div>
                        </div>
                    </div>
                    <div className="modal-footer">
                        <button type="button" className="btn" onClick={onClose}>Cancel</button>
                        <button type="submit" className="btn btn-primary" disabled={loading}>
                            <span className="material-symbols-outlined">add</span>
                            {loading ? 'Adding...' : 'Add Movie'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}
