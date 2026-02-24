import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Service to manage App Lock (PIN + Biometric)
class AppLockService {
  static final AppLockService instance = AppLockService._();
  AppLockService._();

  static const _boxName = 'app_lock';
  static const _keyEnabled = 'enabled';
  static const _keyPinHash = 'pin_hash';
  static const _keyBiometricEnabled = 'biometric_enabled';

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

  // ── PIN Management ──

  String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  Future<void> setPin(String pin) async {
    await _box.put(_keyPinHash, _hashPin(pin));
    await _box.put(_keyEnabled, true);
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
  }

  Future<void> changePin(String newPin) async {
    await _box.put(_keyPinHash, _hashPin(newPin));
  }

  // ── Biometric ──

  Future<void> setBiometric(bool enabled) async {
    await _box.put(_keyBiometricEnabled, enabled);
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      debugPrint('⚠️ Biometric check error: $e');
      return false;
    }
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(localizedReason: 'Unlock MovieHub');
    } catch (e) {
      debugPrint('⚠️ Biometric auth error: $e');
      return false;
    }
  }
}
