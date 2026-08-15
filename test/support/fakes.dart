import 'dart:async';

import 'package:mesa/core/failures/auth_failure.dart';
import 'package:mesa/domain/models/auth_user.dart';
import 'package:mesa/domain/models/user_profile.dart';
import 'package:mesa/domain/repositories/auth_repository.dart';
import 'package:mesa/domain/repositories/user_profile_repository.dart';

/// In-memory [AuthRepository].
///
/// Hand-written rather than mocked: the interface is small, and a fake that
/// actually holds state lets the router tests drive real sign-in/sign-out
/// transitions instead of asserting on calls.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? initialUser, this.emitInitialState = true})
    : _user = initialUser;

  /// When false the stream stays empty, standing in for the window before
  /// Firebase has restored a persisted session — the state the splash covers.
  final bool emitInitialState;

  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;

  /// Set to make the next call fail.
  AuthFailure? nextFailure;

  final List<String> calls = [];

  /// Replays the current identity to each subscriber before following the
  /// controller, the way Firebase reports a restored session. A bare broadcast
  /// stream would drop that first event — nothing is listening yet when the
  /// fake is constructed.
  @override
  Stream<AuthUser?> authStateChanges() async* {
    if (emitInitialState) yield _user;
    yield* _controller.stream;
  }

  @override
  AuthUser? get currentUser => _user;

  /// Signs a user in from outside the auth flows, as Firebase would when it
  /// restores a session.
  void emit(AuthUser? user) {
    _user = user;
    _controller.add(user);
  }

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    calls.add('signUpWithEmail:$email');
    _maybeFail();
    final user = AuthUser(uid: 'uid-$email', email: email, displayName: displayName);
    emit(user);
    return user;
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    calls.add('signInWithEmail:$email');
    _maybeFail();
    final user = AuthUser(uid: 'uid-$email', email: email);
    emit(user);
    return user;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    calls.add('signInWithGoogle');
    _maybeFail();
    const user = AuthUser(
      uid: 'uid-google',
      email: 'google@example.com',
      displayName: 'Google User',
    );
    emit(user);
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    calls.add('sendPasswordResetEmail:$email');
    _maybeFail();
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    _maybeFail();
    emit(null);
  }

  void _maybeFail() {
    final failure = nextFailure;
    if (failure == null) return;
    nextFailure = null;
    throw failure;
  }

  Future<void> dispose() => _controller.close();
}

/// In-memory [UserProfileRepository], keyed by uid so cross-account isolation
/// can be asserted the same way the rules tests assert it.
class FakeUserProfileRepository implements UserProfileRepository {
  final Map<String, UserProfile> profiles = {};
  final Map<String, StreamController<UserProfile?>> _controllers = {};

  StreamController<UserProfile?> _controllerFor(String uid) {
    return _controllers.putIfAbsent(
      uid,
      StreamController<UserProfile?>.broadcast,
    );
  }

  /// Replays the stored document before following the controller — a broadcast
  /// stream on its own would drop everything written before the subscription.
  @override
  Stream<UserProfile?> watch(String uid) async* {
    yield profiles[uid];
    yield* _controllerFor(uid).stream;
  }

  @override
  Future<UserProfile> ensureExists(String uid, {required String displayName}) async {
    final existing = profiles[uid];
    if (existing != null) return existing;

    final now = DateTime.utc(2026);
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
    profiles[uid] = profile;
    _controllerFor(uid).add(profile);
  }

  Future<void> dispose() async {
    for (final controller in _controllers.values) {
      await controller.close();
    }
  }
}
