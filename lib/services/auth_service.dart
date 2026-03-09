import '../models/user_profile.dart';

abstract class AuthService {
  Stream<UserProfile?> get authStateStream;

  Future<void> signIn(String email, String password);

  Future<void> register(String email, String password);

  /// Sends an email-verification message to the currently signed-in user.
  Future<void> sendEmailVerification();

  /// Signs the current user out.
  Future<void> signOut();

  /// Returns the currently signed-in [UserProfile], or `null` if signed out.
  UserProfile? get currentUser;
}

/// Phase-1 stub: the stream always yields `null` (no signed-in user) and all
/// write methods are no-ops.
class StubAuthService implements AuthService {
  @override
  Stream<UserProfile?> get authStateStream => const Stream.empty();

  @override
  Future<void> signIn(String email, String password) async {}

  @override
  Future<void> register(String email, String password) async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> signOut() async {}

  @override
  UserProfile? get currentUser => null;
}
