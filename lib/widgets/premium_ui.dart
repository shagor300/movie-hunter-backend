import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/theme_controller.dart';

/// Animated heart/bookmark pop effect for watchlist toggle.
class WatchlistPopAnimation extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;
  final double size;

  const WatchlistPopAnimation({
    super.key,
    required this.isActive,
    required this.onTap,
    this.size = 28,
  });

  @override
  State<WatchlistPopAnimation> createState() => _WatchlistPopAnimationState();
}

class _WatchlistPopAnimationState extends State<WatchlistPopAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.9), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(WatchlistPopAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive && widget.isActive) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();
    return GestureDetector(
      onTap: () {
        widget.onTap();
        if (!widget.isActive) {
          _controller.forward(from: 0);
        }
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Obx(
            () => Icon(
              widget.isActive ? Icons.bookmark : Icons.bookmark_border,
              color: widget.isActive
                  ? tc.accentColor
                  : Colors.white.withValues(alpha: 0.7),
              size: widget.size,
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated section header with accent dot indicator.
class PremiumSectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const PremiumSectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();

    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Accent dot
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: tc.accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            // Title
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            // Action button
            if (actionText != null)
              GestureDetector(
                onTap: onAction,
                child: Text(
                  actionText!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tc.accentColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Gradient text — makes title text fade from white to accent.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final List<Color>? colors;

  const GradientText({super.key, required this.text, this.style, this.colors});

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();

    return Obx(
      () => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: colors ?? [Colors.white, tc.accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        blendMode: BlendMode.srcIn,
        child: Text(
          text,
          style:
              style ??
              const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

/// Styled FlixHub logo text: "Flix" white + "Hub" accent color.
class FlixHubLogo extends StatelessWidget {
  final double fontSize;
  final FontWeight fontWeight;

  const FlixHubLogo({
    super.key,
    this.fontSize = 22,
    this.fontWeight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();
    return Obx(
      () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Flix',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: Colors.white,
            ),
          ),
          Text(
            'Hub',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: tc.accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pull-to-refresh with accent-colored indicator.
class AccentRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const AccentRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();
    return Obx(
      () => RefreshIndicator(
        onRefresh: onRefresh,
        color: tc.accentColor,
        backgroundColor: const Color(0xFF1A1A2E),
        displacement: 40,
        strokeWidth: 2.5,
        child: child,
      ),
    );
  }
}
