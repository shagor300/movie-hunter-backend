import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Lock type enum for selecting how the app should be locked
enum AppLockType { pin, biometric, both }

/// Service to manage App Lock (PIN + Biometric)
class AppLockService {
  static final AppLockService instance = AppLockService._();
  AppLockService._();

  static const _boxName = 'app_lock';
  static const _keyEnabled = 'enabled';
  static const _keyPinHash = 'pin_hash';
  static const _keyBiometricEnabled = 'biometric_enabled';
  static const _keyLockType = 'lock_type'; // 'pin', 'biometric', 'both'

  late Box _box;
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  // ── State ──

  bool get isLockEnabled => _box.get(_keyEnabled, defaultValue: false);
  bool get isBiometricEnabled =>
      _box.get(_keyBiometricEnabled, defaultValue: false);
  bool get hasPinSet => _box.get(_keyPinHash) != null;

  AppLockType get lockType {
    final type = _box.get(_keyLockType, defaultValue: 'pin');
    switch (type) {
      case 'biometric':
        return AppLockType.biometric;
      case 'both':
        return AppLockType.both;
      default:
        return AppLockType.pin;
    }
  }

  bool get requiresPin =>
      lockType == AppLockType.pin || lockType == AppLockType.both;
  bool get requiresBiometric =>
      lockType == AppLockType.biometric || lockType == AppLockType.both;

  // ── PIN Management ──

  String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  Future<void> setPin(String pin) async {
    await _box.put(_keyPinHash, _hashPin(pin));
    await _box.put(_keyEnabled, true);
    // Default to PIN lock type if enabling for first time
    if (_box.get(_keyLockType) == null) {
      await _box.put(_keyLockType, 'pin');
    }
  }

  bool verifyPin(String pin) {
    final storedHash = _box.get(_keyPinHash);
    if (storedHash == null) return false;
    return storedHash == _hashPin(pin);
  }

  Future<void> disableLock() async {
    await _box.put(_keyEnabled, false);
    await _box.delete(_keyPinHash);
    await _box.put(_keyBiometricEnabled, false);
    await _box.delete(_keyLockType);
  }

  Future<void> changePin(String newPin) async {
    await _box.put(_keyPinHash, _hashPin(newPin));
  }

  // ── Lock Type ──

  Future<void> setLockType(AppLockType type) async {
    switch (type) {
      case AppLockType.pin:
        await _box.put(_keyLockType, 'pin');
        await _box.put(_keyBiometricEnabled, false);
        break;
      case AppLockType.biometric:
        await _box.put(_keyLockType, 'biometric');
        await _box.put(_keyBiometricEnabled, true);
        break;
      case AppLockType.both:
        await _box.put(_keyLockType, 'both');
        await _box.put(_keyBiometricEnabled, true);
        break;
    }
  }

  // ── Biometric ──

  Future<void> setBiometric(bool enabled) async {
    await _box.put(_keyBiometricEnabled, enabled);
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (canCheck && isSupported) {
        // Also verify there are enrolled biometrics
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        return availableBiometrics.isNotEmpty;
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ Biometric check error: $e');
      return false;
    }
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      // Check if biometrics are actually available first
      final isAvail = await isBiometricAvailable();
      if (!isAvail) {
        debugPrint('⚠️ Biometric not available on this device');
        return false;
      }

      debugPrint('🔐 Starting biometric authentication...');
      final result = await _localAuth.authenticate(
        localizedReason: 'Unlock MovieHub',
        biometricOnly: true,
        sensitiveTransaction: false,
        persistAcrossBackgrounding: true,
      );
      debugPrint('🔐 Biometric result: $result');
      return result;
    } catch (e) {
      debugPrint('⚠️ Biometric auth error: $e');
      return false;
    }
  }
}
