import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/movie.dart';
import 'details_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final StorageService _storageService = StorageService();
  List<Movie> _watchlist = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  Future<void> _loadWatchlist() async {
    setState(() => _isLoading = true);
    final data = await _storageService.getWatchlist();
    setState(() {
      _watchlist = data.map((m) => Movie.fromJson(m)).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Watchlist')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _watchlist.isEmpty
          ? const Center(child: Text('Your watchlist is empty'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _watchlist.length,
              itemBuilder: (context, index) {
                final movie = _watchlist[index];
                return Dismissible(
                  key: Key('watchlist-${movie.title}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) async {
                    await _storageService.removeFromWatchlist(movie.title);
                    setState(() {
                      _watchlist.removeAt(index);
                    });
                  },
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailsScreen(movie: movie),
                        ),
                      ).then((_) => _loadWatchlist());
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E3A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                            child: movie.fullPosterPath.isNotEmpty
                                ? Image.network(
                                    movie.fullPosterPath,
                                    width: 70,
                                    fit: BoxFit.cover,
                                  )
                                : Container(width: 70, color: Colors.grey),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    movie.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    movie.releaseDate,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
