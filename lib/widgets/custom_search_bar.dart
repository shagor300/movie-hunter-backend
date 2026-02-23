import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'package:get/get.dart';
import '../theme/theme_controller.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback? onFilterTap;
  final String hintText;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onFilterTap,
    this.hintText = "Search movies, actors, directors...",
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 15,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Obx(
                    () => Icon(
                      Icons.search,
                      color: Get.find<ThemeController>().accentColor,
                      size: 24,
                    ),
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                isDense: true,
              ),
            ),
          ),
        ),
        if (onFilterTap != null) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.tune, color: AppColors.primary, size: 24),
            ),
          ),
        ],
      ],
    );
  }
}
