import 'package:la_pocha/features/auth/domain/entities/user_profile.dart';

abstract class AuthRepository {
  Stream<UserProfile?> get authStateChanges;

  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  Future<UserProfile> signIn({required String email, required String password});

  /// Returns `null` when the user cancels the Google account picker.
  Future<UserProfile?> signInWithGoogle();

  /// Signs in with email/password then links the pending Google credential.
  Future<UserProfile> linkGoogleAccountWithPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// Merges the device local identity into the Firestore user document.
  Future<void> linkLocalId({
    required String firebaseUid,
    required String localId,
  });

  Future<void> sendPasswordReset({required String email});

  Future<UserProfile?> getCurrentUser();

  Future<UserProfile> updateDisplayName(String displayName);

  /// Deletes the Firestore profile and the Firebase Auth user.
  ///
  /// [password] is required when email/password reauthentication is needed.
  Future<void> deleteAccount({String? password});
}
