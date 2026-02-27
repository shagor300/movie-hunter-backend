import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/app_lock_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/theme_controller.dart';

/// Dedicated App Lock settings screen — reached from Settings > Security > App Lock.
class AppLockSettingsScreen extends StatefulWidget {
  const AppLockSettingsScreen({super.key});

  @override
  State<AppLockSettingsScreen> createState() => _AppLockSettingsScreenState();
}

class _AppLockSettingsScreenState extends State<AppLockSettingsScreen> {
  final _lockService = AppLockService.instance;
  bool _bioAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await _lockService.isBiometricAvailable();
    if (mounted) setState(() => _bioAvailable = available);
  }

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();
    final accent = tc.accentColor;
    final isEnabled = _lockService.isLockEnabled;
    final currentType = _lockService.lockType;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'App Lock',
          style: AppTextStyles.headingLarge.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        children: [
          // ═══ LOCK ICON HEADER ═══
          _buildHeader(accent, isEnabled),
          const SizedBox(height: 24),

          // ═══ ENABLE/DISABLE TOGGLE ═══
          _buildCard([
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isEnabled
                          ? [accent, accent.withValues(alpha: 0.6)]
                          : [Colors.white12, Colors.white10],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isEnabled ? Icons.lock_rounded : Icons.lock_open_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App Lock',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isEnabled
                            ? 'Authentication required to open app'
                            : 'No authentication required',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: (val) {
                    HapticFeedback.lightImpact();
                    if (val) {
                      _showPinSetupDialog();
                    } else {
                      _disableLock();
                    }
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: accent,
                  inactiveThumbColor: AppColors.textMuted,
                  inactiveTrackColor: Colors.white10,
                ),
              ],
            ),
          ]),

          // ═══ LOCK METHOD SELECTION ═══
          if (isEnabled) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.security_rounded, size: 16, color: accent),
                  const SizedBox(width: 8),
                  Text(
                    'LOCK METHOD',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            _buildCard([
              _buildLockOption(
                icon: Icons.dialpad_rounded,
                title: 'PIN Only',
                subtitle: '4-digit PIN code',
                isSelected: currentType == AppLockType.pin,
                accent: accent,
                onTap: () {
                  if (!_lockService.hasPinSet) {
                    _showPinSetupDialog();
                  } else {
                    _lockService.setLockType(AppLockType.pin);
                    setState(() {});
                  }
                },
              ),
              if (_bioAvailable) ...[
                const Divider(color: Colors.white10, height: 24),
                _buildLockOption(
                  icon: Icons.fingerprint_rounded,
                  title: 'Biometric Only',
                  subtitle: 'Fingerprint or face unlock',
                  isSelected: currentType == AppLockType.biometric,
                  accent: accent,
                  onTap: () {
                    _lockService.setLockType(AppLockType.biometric);
                    setState(() {});
                  },
                ),
                const Divider(color: Colors.white10, height: 24),
                _buildLockOption(
                  icon: Icons.shield_rounded,
                  title: 'PIN + Biometric',
                  subtitle: 'Use either method to unlock',
                  isSelected: currentType == AppLockType.both,
                  accent: accent,
                  onTap: () {
                    if (!_lockService.hasPinSet) {
                      _showPinSetupDialog();
                    } else {
                      _lockService.setLockType(AppLockType.both);
                      setState(() {});
                    }
                  },
                ),
              ],
            ]),

            // ═══ CHANGE PIN ═══
            if (_lockService.hasPinSet) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.vpn_key_rounded, size: 16, color: accent),
                    const SizedBox(width: 8),
                    Text(
                      'PIN MANAGEMENT',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
              _buildCard([
                GestureDetector(
                  onTap: () => _showChangePinDialog(),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.orangeAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Change PIN',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Set a new 4-digit PIN code',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white24,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ]),
            ],
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // UI HELPERS
  // ═══════════════════════════════════════

  Widget _buildHeader(Color accent, bool isEnabled) {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isEnabled
                ? [accent.withValues(alpha: 0.3), accent.withValues(alpha: 0.1)]
                : [Colors.white10, Colors.white.withValues(alpha: 0.03)],
          ),
          border: Border.all(
            color: isEnabled ? accent.withValues(alpha: 0.4) : Colors.white10,
            width: 2,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.2),
                    blurRadius: 30,
                  ),
                ]
              : [],
        ),
        child: Icon(
          isEnabled ? Icons.lock_rounded : Icons.lock_open_rounded,
          size: 40,
          color: isEnabled ? accent : Colors.white38,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151928),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildLockOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? accent.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? accent.withValues(alpha: 0.3)
                    : Colors.white10,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? accent : Colors.white38,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? accent : Colors.transparent,
              border: Border.all(
                color: isSelected ? accent : Colors.white24,
                width: 2,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════

  void _disableLock() {
    if (_lockService.lockType == AppLockType.biometric) {
      _lockService.authenticateWithBiometric().then((ok) {
        if (ok) {
          _lockService.disableLock();
          setState(() {});
        }
      });
    } else {
      _showPinVerifyDialog(
        onSuccess: () {
          _lockService.disableLock();
          setState(() {});
        },
      );
    }
  }

  void _showPinSetupDialog() {
    final pinController = TextEditingController();
    String pin1 = '';
    bool isConfirm = false;
    bool isError = false;
    String errorMsg = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isConfirm ? 'Confirm PIN' : 'Create PIN',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isConfirm
                    ? 'Enter your PIN again to confirm'
                    : 'Enter a 4-digit PIN',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: pinController,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  letterSpacing: 12,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '• • • •',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.white24,
                    fontSize: 28,
                    letterSpacing: 12,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                  ),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  if (value.length == 4) {
                    if (!isConfirm) {
                      pin1 = value;
                      pinController.clear();
                      setDialogState(() {
                        isConfirm = true;
                        isError = false;
                      });
                    } else {
                      if (value == pin1) {
                        AppLockService.instance.setPin(value).then((_) {
                          setState(() {});
                          if (ctx.mounted) Navigator.pop(ctx);
                        });
                      } else {
                        pinController.clear();
                        setDialogState(() {
                          isConfirm = false;
                          isError = true;
                          errorMsg = 'PINs do not match. Try again.';
                          pin1 = '';
                        });
                      }
                    }
                  }
                },
              ),
              if (isError) ...[
                const SizedBox(height: 12),
                Text(
                  errorMsg,
                  style: GoogleFonts.inter(
                    color: Colors.redAccent,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPinVerifyDialog({required VoidCallback onSuccess}) {
    final pinController = TextEditingController();
    bool isError = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Enter PIN',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter current PIN to continue',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: pinController,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  letterSpacing: 12,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '• • • •',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.white24,
                    fontSize: 28,
                    letterSpacing: 12,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                  ),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  if (value.length == 4) {
                    if (AppLockService.instance.verifyPin(value)) {
                      Navigator.pop(ctx);
                      onSuccess();
                      setState(() {});
                    } else {
                      pinController.clear();
                      setDialogState(() => isError = true);
                    }
                  }
                },
              ),
              if (isError) ...[
                const SizedBox(height: 12),
                Text(
                  'Incorrect PIN',
                  style: GoogleFonts.inter(
                    color: Colors.redAccent,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePinDialog() {
    _showPinVerifyDialog(
      onSuccess: () {
        _showPinSetupDialog();
      },
    );
  }
}
