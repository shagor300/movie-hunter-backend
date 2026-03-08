import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../widgets/movie_card.dart';
import 'details_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  Movie? _featuredMovie;
  List<Movie> _trendingMovies = [];
  List<Movie> _latestMovies = [];
  bool _loading = true;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      // Load all sections in parallel
      final results = await Future.wait([
        _apiService.getFeatured(),
        _apiService.getTrending(limit: 20),
        _apiService.getLatest(limit: 20),
      ]);

      if (mounted) {
        setState(() {
          _featuredMovie = results[0] as Movie?;
          _trendingMovies = (results[1] as List).cast<Movie>();
          _latestMovies = (results[2] as List).cast<Movie>();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Load home data error: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.transparent, // Let parent background show
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent, // Let parent background show
      body: RefreshIndicator(
        onRefresh: _loadHomeData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Featured Movie
              if (_featuredMovie != null)
                _buildFeaturedSection(_featuredMovie!),

              SizedBox(height: 24),

              // Trending Section
              _buildMovieSection(
                title: '🔥 Trending Now',
                movies: _trendingMovies,
              ),

              SizedBox(height: 24),

              // Latest Section
              _buildMovieSection(title: '🆕 Latest', movies: _latestMovies),

              SizedBox(height: 100), // padding for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedSection(Movie movie) {
    return GestureDetector(
      onTap: () => _openMovieDetails(movie),
      child: SizedBox(
        height: 500,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image with Gradient Overlay
            if (movie.fullPosterPath.isNotEmpty)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: movie.fullPosterPath.replaceAll('w500', 'original'),
                  fit: BoxFit.cover,
                  errorWidget: (context, url, err) => SizedBox(),
                ),
              )
            else
              SizedBox(),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xFF0F0F23).withValues(alpha: 0.5),
                    Color(0xFF0F0F23),
                  ],
                ),
              ),
            ),

            // Movie info
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'FEATURED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(height: 12),

                  Text(
                    movie.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Row(
                    children: [
                      if (movie.rating > 0) ...[
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        SizedBox(width: 4),
                        Text(
                          movie.rating.toStringAsFixed(1),
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        SizedBox(width: 16),
                      ],
                      if (movie.year.isNotEmpty)
                        Text(
                          movie.year,
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                    ],
                  ),

                  SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openMovieDetails(movie),
                      icon: Icon(Icons.play_arrow),
                      label: Text('Watch Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.all(16),
                        textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieSection({
    required String title,
    required List<Movie> movies,
  }) {
    if (movies.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SizedBox(height: 12),

        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              return MovieCard(
                movie: movies[index],
                onTap: () => _openMovieDetails(movies[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openMovieDetails(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailsScreen(movie: movie)),
    );
  }
}
