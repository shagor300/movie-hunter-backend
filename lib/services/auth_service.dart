import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Handles Firebase Authentication — auto guest sign-in.
///
/// Usage:
///   await AuthService.instance.ensureSignedIn();
///   final user = AuthService.instance.currentUser;
///   final uid = AuthService.instance.uid;
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// The currently signed-in user (or null).
  User? get currentUser => _auth.currentUser;

  /// Shortcut for the current user's UID.
  String? get uid => _auth.currentUser?.uid;

  /// Whether a user is currently signed in.
  bool get isSignedIn => _auth.currentUser != null;

  /// Whether the current user is anonymous (guest).
  bool get isGuest => _auth.currentUser?.isAnonymous ?? true;

  /// Ensure the user is signed in. If not, sign in anonymously.
  /// Call this once during app startup.
  Future<void> ensureSignedIn() async {
    if (_auth.currentUser != null) {
      debugPrint('✅ Auth: Already signed in — UID: ${_auth.currentUser!.uid}');
      return;
    }

    try {
      final credential = await _auth.signInAnonymously();
      debugPrint(
        '✅ Auth: Guest sign-in — UID: ${credential.user?.uid}',
      );
    } catch (e) {
      debugPrint('❌ Auth: Anonymous sign-in failed: $e');
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
    debugPrint('✅ Auth: Signed out');
  }

  /// Listen to auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
