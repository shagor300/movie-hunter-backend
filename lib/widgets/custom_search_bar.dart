import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'package:get/get.dart';
import '../theme/theme_controller.dart';

class CustomSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onVoiceTap;
  final VoidCallback? onSubmitted;
  final String hintText;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onFilterTap,
    this.onVoiceTap,
    this.onSubmitted,
    this.hintText = "Search movies, series...",
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
      if (_focusNode.hasFocus) {
        _glowController.repeat(reverse: true);
      } else {
        _glowController.stop();
        _glowController.value = 0;
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();

    return Obx(() {
      final accent = tc.accentColor;

      return AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            height: 52,
            decoration: BoxDecoration(
              color: _isFocused
                  ? AppColors.surfaceLight.withValues(alpha: 0.7)
                  : AppColors.surfaceLight.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused
                    ? accent.withValues(alpha: _glowAnimation.value)
                    : AppColors.glassBorder,
                width: _isFocused ? 1.5 : 1,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.12),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: child,
          );
        },
        child: Row(
          children: [
            // Search icon with animation
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _isFocused ? Icons.search_rounded : Icons.search,
                  key: ValueKey(_isFocused),
                  color: _isFocused ? accent : AppColors.textMuted,
                  size: 22,
                ),
              ),
            ),
            // Text field
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted != null
                    ? (_) => widget.onSubmitted!()
                    : null,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
                cursorColor: accent,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  isDense: true,
                ),
              ),
            ),
            // Clear button (shown when text is present)
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () {
                    widget.controller.clear();
                    widget.onChanged('');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
            // Voice search icon
            if (widget.onVoiceTap != null)
              GestureDetector(
                onTap: widget.onVoiceTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.mic_rounded,
                    color: _isFocused ? accent : accent.withValues(alpha: 0.6),
                    size: 22,
                  ),
                ),
              ),
            // Filter icon
            if (widget.onFilterTap != null)
              GestureDetector(
                onTap: widget.onFilterTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 36,
                  width: 36,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.tune_rounded, color: accent, size: 18),
                ),
              ),
          ],
        ),
      );
    });
  }
}
