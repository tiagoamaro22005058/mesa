import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesa/data/firestore/converters/user_profile_converter.dart';
import 'package:mesa/domain/models/user_profile.dart';
import 'package:mesa/domain/repositories/user_profile_repository.dart';

/// [UserProfileRepository] backed by the `users/{uid}` document (§4).
class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// The only collection M1 touches. Everything user-owned hangs off this
  /// document, which is what makes §4.3's rules a single path match.
  static const String usersCollection = 'users';

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection(usersCollection).doc(uid);

  @override
  Stream<UserProfile?> watch(String uid) {
    return _doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      return data == null ? null : UserProfileConverter.fromMap(data);
    });
  }

  @override
  Future<UserProfile> ensureExists(String uid, {required String displayName}) async {
    // Waits for an answer that can be trusted: either the document is known to
    // exist (cache or server), or the server has authoritatively said it does
    // not. Creating on a cache miss alone would let a signed-in user with a
    // cold cache overwrite their real profile with defaults once it synced.
    //
    // Offline with an empty cache this never completes, which is correct — it
    // is only reached after a sign-in, and sign-in needs the network anyway
    // (NFR1). Callers treat it as a side effect and never block the UI on it.
    final snapshot = await _doc(uid).snapshots().firstWhere(
      (s) => s.exists || !s.metadata.isFromCache,
    );

    final data = snapshot.data();
    if (data != null) return UserProfileConverter.fromMap(data);

    final now = DateTime.now().toUtc();
    final profile = UserProfile(
      displayName: displayName,
      createdAt: now,
      updatedAt: now,
    );
    await save(uid, profile);
    return profile;
  }

  @override
  Future<void> save(String uid, UserProfile profile) async {
    // Deliberately not awaited. Firestore completes a write's future only when
    // the server acknowledges it, so awaiting hangs indefinitely with no
    // connectivity (NFR1) and costs a round-trip with it (NFR3). The write is
    // applied to the local cache synchronously and watch() re-emits from there,
    // so the UI updates either way and the SDK syncs when it can.
    unawaited(_doc(uid).set(UserProfileConverter.toMap(profile)));
  }
}
