import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../theme/theme_controller.dart';

/// Premium animated empty state with breathing glow and accent color.
class EmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.08, end: 0.2).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Obx(() {
          final accent = tc.accentColor;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Breathing animated icon
              AnimatedBuilder(
                animation: _breathingController,
                builder: (context, _) => Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(alpha: _glowAnimation.value),
                          accent.withValues(alpha: 0.02),
                        ],
                        radius: 0.85,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(
                            alpha: _glowAnimation.value * 0.5,
                          ),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      size: 48,
                      color: accent.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Title
              Text(
                widget.title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              // Message
              Text(
                widget.message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.45),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              // Action button
              if (widget.actionLabel != null && widget.onAction != null) ...[
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: widget.onAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.explore_outlined, size: 18, color: accent),
                        const SizedBox(width: 8),
                        Text(
                          widget.actionLabel!,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}
