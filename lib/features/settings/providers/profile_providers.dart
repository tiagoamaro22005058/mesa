import 'dart:async';

import 'package:mesa/domain/models/user_profile.dart';
import 'package:mesa/features/auth/providers/auth_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_providers.g.dart';

/// The signed-in user's profile document (§4), or `null` while it does not
/// exist yet.
///
/// Auto-disposed and scoped to the current uid, which is what lets sign-out
/// drop every Firestore listener before the cache is cleared — see
/// `FirebaseAuthRepository.signOut`.
@riverpod
Stream<UserProfile?> userProfile(Ref ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(null);

  return ref.watch(userProfileRepositoryProvider).watch(uid);
}

/// Writes profile edits (F1).
@riverpod
class ProfileController extends _$ProfileController {
  @override
  FutureOr<void> build() {}

  Future<void> save(UserProfile profile) async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(userProfileRepositoryProvider)
          .save(uid, profile.copyWith(updatedAt: DateTime.now().toUtc())),
    );

    // The screen can be gone by now — signing out mid-save disposes it.
    if (!ref.mounted) return;
    state = result;
  }
}
