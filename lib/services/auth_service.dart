import 'package:firebase_auth/firebase_auth.dart';

/// Anonymous authentication for V1. Firestore rules require
/// `request.auth != null` — this satisfies that without staff logins.
/// V2 will replace this with per-staff email/password authentication.
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sign in anonymously. Called once at app startup.
  /// Returns the User on success, null on failure.
  static Future<User?> signInAnonymously() async {
    try {
      // If already signed in, reuse the session.
      if (_auth.currentUser != null) return _auth.currentUser;

      final credential = await _auth.signInAnonymously();
      return credential.user;
    } catch (e) {
      // Offline launch — Firestore cache still works even without auth
      // on first launch. Auth will succeed on next online startup.
      return null;
    }
  }

  /// Current user ID (anonymous UID), or 'offline' if not yet signed in.
  static String get currentUserId =>
      _auth.currentUser?.uid ?? 'offline';

  /// Whether the user has an active auth session.
  static bool get isSignedIn => _auth.currentUser != null;
}
