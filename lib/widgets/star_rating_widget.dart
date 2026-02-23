import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Interactive star rating widget with half-star precision.
class StarRatingWidget extends StatelessWidget {
  final double rating;
  final double maxRating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<double>? onRatingChanged;
  final bool showLabel;

  const StarRatingWidget({
    super.key,
    this.rating = 0,
    this.maxRating = 5,
    this.size = 32,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.white24,
    this.onRatingChanged,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(maxRating.toInt(), (index) {
          final starValue = index + 1.0;
          final halfStarValue = index + 0.5;

          IconData icon;
          Color color;

          if (rating >= starValue) {
            icon = Icons.star_rounded;
            color = activeColor;
          } else if (rating >= halfStarValue) {
            icon = Icons.star_half_rounded;
            color = activeColor;
          } else {
            icon = Icons.star_outline_rounded;
            color = inactiveColor;
          }

          return GestureDetector(
            onTapDown: onRatingChanged == null
                ? null
                : (details) {
                    HapticFeedback.lightImpact();
                    // Determine if tap was on left or right half of star
                    final tapX = details.localPosition.dx;
                    final isLeftHalf = tapX < size / 2;
                    final newRating = isLeftHalf ? halfStarValue : starValue;
                    onRatingChanged!(newRating);
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  key: ValueKey('$index-$icon'),
                  size: size,
                  color: color,
                ),
              ),
            ),
          );
        }),
        if (showLabel && rating > 0) ...[
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.poppins(
              color: activeColor,
              fontSize: size * 0.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}
