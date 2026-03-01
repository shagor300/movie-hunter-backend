import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_update_info.dart';
import '../controllers/update_controller.dart';

/// Premium update dialog — shows when a new version is available.
/// [isForce] = true → non-dismissible, no skip button.
class UpdateDialog extends StatelessWidget {
  final AppUpdateInfo info;
  final bool isForce;

  const UpdateDialog({super.key, required this.info, this.isForce = false});

  /// Show the update dialog globally via GetX.
  static void show(AppUpdateInfo info) {
    Get.dialog(
      UpdateDialog(info: info, isForce: info.isForceUpdate),
      barrierDismissible: !info.isForceUpdate,
      barrierColor: Colors.black87,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF00E5A0);

    return PopScope(
      canPop: !isForce,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primary.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.1),
                blurRadius: 40,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      primary.withValues(alpha: 0.3),
                      primary.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: Icon(
                  isForce
                      ? Icons.security_update_warning_rounded
                      : Icons.system_update_rounded,
                  color: primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                isForce ? 'Critical Update Required' : 'Update Available',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // Version badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'v${info.latestVersionName}',
                  style: GoogleFonts.inter(
                    color: primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // What's new
              if (info.whatsNew.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "What's New",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: info.whatsNew
                        .take(5)
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '•  ',
                                  style: TextStyle(
                                    color: primary,
                                    fontSize: 13,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: GoogleFonts.inter(
                                      color: Colors.white60,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Force update warning
              if (isForce) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This update is required to continue using the app.',
                          style: GoogleFonts.inter(
                            color: Colors.redAccent.withValues(alpha: 0.9),
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Update button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    try {
                      final controller = Get.find<UpdateController>();
                      controller.downloadUpdate();
                    } catch (_) {}
                    if (!isForce) Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Update Now',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // Skip button (only for optional)
              if (!isForce) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'Maybe Later',
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
