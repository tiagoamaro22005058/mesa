import 'package:mesa/domain/models/user_profile.dart';

/// The `users/{uid}` document (§4, F1).
abstract interface class UserProfileRepository {
  /// Watches the profile. Emits `null` while the document does not exist.
  ///
  /// Backed by the offline cache, so it emits without connectivity (NFR1).
  Stream<UserProfile?> watch(String uid);

  /// Creates the profile with §4's defaults if it is absent, and returns it
  /// either way.
  ///
  /// Called on every successful authentication rather than only on sign-up:
  /// Google Sign-In creates accounts implicitly, so there is no sign-up path
  /// to hang this off.
  Future<UserProfile> ensureExists(String uid, {required String displayName});

  Future<void> save(String uid, UserProfile profile);
}
