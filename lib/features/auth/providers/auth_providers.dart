import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mesa/data/firestore/firebase_auth_repository.dart';
import 'package:mesa/data/firestore/firestore_user_profile_repository.dart';
import 'package:mesa/domain/models/auth_user.dart';
import 'package:mesa/domain/repositories/auth_repository.dart';
import 'package:mesa/domain/repositories/user_profile_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

/// The auth backend.
///
/// Overridden with a fake in tests, which is what keeps widget tests free of
/// Firebase plugin channels — `FirebaseAuth.instance` is never constructed
/// unless something actually reads this.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => FirebaseAuthRepository(
  FirebaseAuth.instance,
  FirebaseFirestore.instance,
  GoogleSignIn.instance,
);

/// The `users/{uid}` document store (§4).
@Riverpod(keepAlive: true)
UserProfileRepository userProfileRepository(Ref ref) =>
    FirestoreUserProfileRepository(FirebaseFirestore.instance);

/// The signed-in identity, or `null` when signed out.
///
/// Stays `AsyncLoading` until Firebase has restored any persisted session, so
/// the router can show a splash rather than flashing the sign-in screen on a
/// cold start (F1).
@Riverpod(keepAlive: true)
Stream<AuthUser?> authState(Ref ref) =>
    ref.watch(authRepositoryProvider).authStateChanges();

/// Creates the `users/{uid}` document the first time an account authenticates.
///
/// Hangs off the auth state rather than the sign-up call because Google
/// Sign-In creates accounts implicitly — there is no sign-up path to hook. It
/// is idempotent, so running again on every restored session is harmless.
///
/// Activated by [MesaApp]; nothing else needs to read it.
@Riverpod(keepAlive: true)
void profileBootstrap(Ref ref) {
  ref.listen<AsyncValue<AuthUser?>>(authStateProvider, (previous, next) {
    final user = next.value;
    if (user == null || previous?.value?.uid == user.uid) return;

    unawaited(_ensureProfile(ref, user));
  }, fireImmediately: true);
}

/// Offline this never completes, which is fine — it is a side effect, not
/// something the UI waits on. A failure must not surface as an uncaught async
/// error in the widget that activated the bootstrap.
Future<void> _ensureProfile(Ref ref, AuthUser user) async {
  try {
    await ref
        .read(userProfileRepositoryProvider)
        .ensureExists(user.uid, displayName: displayNameFor(user));
  } on Object {
    // The profile screen reads the document through its own stream and will
    // report an absent profile on its own terms.
  }
}

/// Best display name available for a fresh profile.
///
/// Google supplies one; email sign-up sets one explicitly. The email local
/// part is the fallback so the profile is never created blank.
String displayNameFor(AuthUser user) {
  final fromProvider = user.displayName?.trim();
  if (fromProvider != null && fromProvider.isNotEmpty) return fromProvider;

  final email = user.email;
  if (email != null && email.contains('@')) return email.split('@').first;

  return '';
}

/// Drives the auth screens. Its [AsyncValue] carries the in-flight and failed
/// states that the forms render.
@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _run(
      () => ref
          .read(authRepositoryProvider)
          .signUpWithEmail(
            email: email.trim(),
            password: password,
            displayName: displayName.trim(),
          ),
    );
  }

  Future<void> signIn({required String email, required String password}) {
    return _run(
      () => ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: email.trim(), password: password),
    );
  }

  Future<void> signInWithGoogle() {
    return _run(() => ref.read(authRepositoryProvider).signInWithGoogle());
  }

  Future<void> sendPasswordReset(String email) {
    return _run(
      () => ref.read(authRepositoryProvider).sendPasswordResetEmail(email.trim()),
    );
  }

  Future<void> signOut() {
    return _run(() => ref.read(authRepositoryProvider).signOut());
  }

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);

    // A successful sign-in or sign-out moves the router, which disposes the
    // screen watching this controller — and with it the controller. Writing
    // state afterwards would throw on a dead Ref.
    if (!ref.mounted) return;
    state = result;
  }
}
