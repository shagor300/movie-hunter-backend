import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_lock_service.dart';

/// Fullscreen lock screen with PIN entry and optional biometric unlock
class AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const AppLockScreen({super.key, required this.onUnlocked});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen>
    with SingleTickerProviderStateMixin {
  final _lockService = AppLockService.instance;
  String _enteredPin = '';
  bool _isError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 24).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Try biometric on launch if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometric();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    if (!_lockService.requiresBiometric) return;
    final success = await _lockService.authenticateWithBiometric();
    if (success && mounted) widget.onUnlocked();
  }

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();
    if (key == 'delete') {
      if (_enteredPin.isNotEmpty) {
        setState(() {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
          _isError = false;
        });
      }
      return;
    }
    if (key == 'bio') {
      _tryBiometric();
      return;
    }

    if (_enteredPin.length >= 4) return;

    setState(() {
      _enteredPin += key;
      _isError = false;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _verifyPin() {
    if (_lockService.verifyPin(_enteredPin)) {
      widget.onUnlocked();
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);
      setState(() {
        _isError = true;
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBiometricOnly = _lockService.lockType == AppLockType.biometric;
    final showBioButton = _lockService.requiresBiometric;

    // Biometric-only mode — no PIN pad, just fingerprint
    if (isBiometricOnly) {
      return _buildBiometricOnlyScreen();
    }

    // PIN mode (or both) — show PIN pad with optional bio button
    return _buildPinScreen(showBioButton);
  }

  Widget _buildBiometricOnlyScreen() {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // Fingerprint icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    primary.withValues(alpha: 0.3),
                    primary.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Icon(Icons.fingerprint_rounded, color: primary, size: 52),
            ),
            const SizedBox(height: 32),

            Text(
              'Biometric Required',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Touch the fingerprint sensor to unlock',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 40),

            // Retry button
            GestureDetector(
              onTap: _tryBiometric,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fingerprint_rounded, color: primary, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Tap to Unlock',
                      style: GoogleFonts.inter(
                        color: primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildPinScreen(bool showBioButton) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Lock icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Icon(
                Icons.lock_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Enter PIN',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isError ? 'Wrong PIN, try again' : 'Enter your 4-digit PIN',
              style: GoogleFonts.inter(
                color: _isError ? Colors.redAccent : Colors.white38,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // PIN dots
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    _shakeController.isAnimating
                        ? _shakeAnimation.value *
                              ((_shakeController.value * 10).round().isEven
                                  ? 1
                                  : -1)
                        : 0,
                    0,
                  ),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final isFilled = i < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: isFilled ? 18 : 16,
                    height: isFilled ? 18 : 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isError
                          ? Colors.redAccent
                          : isFilled
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white.withValues(alpha: 0.1),
                      border: Border.all(
                        color: _isError
                            ? Colors.redAccent
                            : isFilled
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white.withValues(alpha: 0.2),
                        width: 2,
                      ),
                      boxShadow: isFilled
                          ? [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            ),

            const Spacer(flex: 1),

            // Numpad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  _buildNumRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _buildNumRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _buildNumRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  _buildNumRow([showBioButton ? 'bio' : '', '0', 'delete']),
                ],
              ),
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildNumRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key.isEmpty) return const SizedBox(width: 72, height: 72);

        if (key == 'delete') {
          return _buildKeyButton(
            child: const Icon(
              Icons.backspace_outlined,
              color: Colors.white70,
              size: 24,
            ),
            onTap: () => _onKeyTap('delete'),
          );
        }

        if (key == 'bio') {
          return _buildKeyButton(
            child: Icon(
              Icons.fingerprint_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            onTap: () => _onKeyTap('bio'),
          );
        }

        return _buildKeyButton(
          child: Text(
            key,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () => _onKeyTap(key),
        );
      }).toList(),
    );
  }

  Widget _buildKeyButton({required Widget child, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(36),
        splashColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.15),
        highlightColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.05),
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: child,
        ),
      ),
    );
  }
}
