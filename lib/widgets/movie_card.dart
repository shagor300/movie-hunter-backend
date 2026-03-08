import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const MovieCard({super.key, required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Poster image
                  movie.fullPosterPath.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: movie.fullPosterPath.replaceAll(
                            'w500',
                            'w342',
                          ), // optimize image size
                          height: 200,
                          width: 140,
                          fit: BoxFit.cover,
                          httpHeaders: const {'User-Agent': 'Mozilla/5.0'},
                          placeholder: (context, url) => Container(
                            color: Colors.grey[800],
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white54,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[800],
                            child: Icon(
                              Icons.movie,
                              size: 50,
                              color: Colors.white54,
                            ),
                          ),
                        )
                      : Container(
                          height: 200,
                          width: 140,
                          color: Colors.grey[800],
                          child: Center(
                            child: Icon(
                              Icons.movie,
                              size: 50,
                              color: Colors.white54,
                            ),
                          ),
                        ),

                  // Rating badge (bottom-left) - ONLY badge allowed!
                  if (movie.rating > 0)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 12),
                            SizedBox(width: 2),
                            Text(
                              movie.rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 8),

            // Title
            Text(
              movie.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Year
            if (movie.year.isNotEmpty)
              Text(
                movie.year,
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }
}
