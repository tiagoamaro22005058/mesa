import 'dart:async';

import 'package:mesa/core/failures/auth_failure.dart';
import 'package:mesa/core/failures/catalog_failure.dart';
import 'package:mesa/core/failures/firestore_failure.dart';
import 'package:mesa/core/ids.dart';
import 'package:mesa/domain/models/auth_user.dart';
import 'package:mesa/domain/models/day.dart';
import 'package:mesa/domain/models/exercise.dart';
import 'package:mesa/domain/models/program.dart';
import 'package:mesa/domain/models/user_profile.dart';
import 'package:mesa/domain/repositories/auth_repository.dart';
import 'package:mesa/domain/repositories/custom_exercise_repository.dart';
import 'package:mesa/domain/repositories/exercise_catalog.dart';
import 'package:mesa/domain/repositories/program_repository.dart';
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

/// In-memory [ExerciseCatalog].
///
/// Holds a handful of exercises rather than the real 1,295: a widget test that
/// parsed the whole asset would spend more time on JSON than on the screen it
/// is testing. `bundled_catalog_test.dart` is what proves the real asset loads.
class FakeExerciseCatalog implements ExerciseCatalog {
  FakeExerciseCatalog({this.exercises = const []});

  List<Exercise> exercises;

  /// Set to make [load] fail, standing in for an asset that never shipped.
  CatalogFailure? failure;

  int loadCount = 0;

  @override
  Future<List<Exercise>> load() async {
    loadCount++;
    final failure = this.failure;
    if (failure != null) throw failure;
    return exercises;
  }
}

/// In-memory [CustomExerciseRepository], keyed by uid so cross-account
/// isolation can be asserted here the way the rules tests assert it.
class FakeCustomExerciseRepository implements CustomExerciseRepository {
  final Map<String, List<Exercise>> exercises = {};
  final Map<String, StreamController<List<Exercise>>> _controllers = {};

  StreamController<List<Exercise>> _controllerFor(String uid) {
    return _controllers.putIfAbsent(uid, StreamController<List<Exercise>>.broadcast);
  }

  /// Replays what is stored before following the controller — a broadcast
  /// stream alone would drop everything written before the subscription.
  @override
  Stream<List<Exercise>> watch(String uid) async* {
    yield exercises[uid] ?? const [];
    yield* _controllerFor(uid).stream;
  }

  @override
  Future<void> save(String uid, Exercise exercise) async {
    final owned = [...?exercises[uid]]..removeWhere((e) => e.id == exercise.id);
    owned.add(exercise);
    owned.sort((a, b) => a.name.compareTo(b.name));
    exercises[uid] = owned;
    _controllerFor(uid).add(owned);
  }

  @override
  Future<void> delete(String uid, String exerciseId) async {
    final owned = [...?exercises[uid]]..removeWhere((e) => e.id == exerciseId);
    exercises[uid] = owned;
    _controllerFor(uid).add(owned);
  }

  Future<void> dispose() async {
    for (final controller in _controllers.values) {
      await controller.close();
    }
  }
}

/// In-memory [ProgramRepository], keyed by uid so cross-account isolation can
/// be asserted here the way the rules tests assert it.
///
/// Give it the [FakeUserProfileRepository] the test is using to reproduce
/// [activate]'s batch: §4 stores the active program on the program document
/// *and* on the profile, and a fake that only wrote one of them would let a
/// test pass while the real invariant was broken.
class FakeProgramRepository implements ProgramRepository {
  FakeProgramRepository({this.profiles});

  final FakeUserProfileRepository? profiles;

  final Map<String, List<Program>> programs = {};

  /// Keyed by `'$uid/$programId'`.
  final Map<String, List<Day>> days = {};

  final Map<String, StreamController<List<Program>>> _programControllers = {};
  final Map<String, StreamController<List<Day>>> _dayControllers = {};

  StreamController<List<Program>> _programControllerFor(String uid) =>
      _programControllers.putIfAbsent(uid, StreamController<List<Program>>.broadcast);

  StreamController<List<Day>> _dayControllerFor(String key) =>
      _dayControllers.putIfAbsent(key, StreamController<List<Day>>.broadcast);

  String _key(String uid, String programId) => '$uid/$programId';

  List<Program> _sortedPrograms(String uid) {
    final owned = [...?programs[uid]]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return owned;
  }

  List<Day> _sortedDays(String uid, String programId) {
    final owned = [...?days[_key(uid, programId)]]
      ..sort((a, b) => a.order.compareTo(b.order));
    return owned;
  }

  /// Replays what is stored before following the controller — a broadcast
  /// stream alone would drop everything written before the subscription.
  @override
  Stream<List<Program>> watchPrograms(String uid) async* {
    yield _sortedPrograms(uid);
    yield* _programControllerFor(uid).stream;
  }

  @override
  Stream<List<Day>> watchDays(String uid, String programId) async* {
    yield _sortedDays(uid, programId);
    yield* _dayControllerFor(_key(uid, programId)).stream;
  }

  @override
  Future<void> saveProgram(String uid, Program program) async {
    final owned = [...?programs[uid]]..removeWhere((p) => p.id == program.id);
    owned.add(program);
    programs[uid] = owned;
    _emitPrograms(uid);
  }

  @override
  Future<void> saveDay(String uid, String programId, Day day) async {
    final key = _key(uid, programId);
    final owned = [...?days[key]]..removeWhere((d) => d.id == day.id);
    owned.add(day);
    days[key] = owned;
    _emitDays(uid, programId);
  }

  @override
  Future<void> deleteDay(String uid, String programId, String dayId) async {
    final key = _key(uid, programId);
    days[key] = [...?days[key]]..removeWhere((d) => d.id == dayId);
    _emitDays(uid, programId);
  }

  @override
  Future<void> reorderDays(String uid, String programId, List<Day> ordered) async {
    final key = _key(uid, programId);
    days[key] = [
      for (final (index, day) in ordered.indexed) day.copyWith(order: index),
    ];
    _emitDays(uid, programId);
  }

  @override
  Future<String> duplicateProgram(
    String uid,
    String programId, {
    required String name,
  }) async {
    final source = [...?programs[uid]].where((p) => p.id == programId).firstOrNull;
    if (source == null) {
      throw const FirestoreFailure(FirestoreFailureKind.notFound);
    }

    final now = DateTime.now().toUtc();
    final copyId = newId('program');
    await saveProgram(
      uid,
      source.copyWith(
        id: copyId,
        name: name,
        status: ProgramStatus.draft,
        createdAt: now,
        updatedAt: now,
      ),
    );

    for (final day in _sortedDays(uid, programId)) {
      await saveDay(uid, copyId, _withFreshIds(day));
    }

    return copyId;
  }

  @override
  Future<Day> duplicateDay(
    String uid,
    String programId,
    Day day, {
    required String name,
  }) async {
    final copy = _withFreshIds(day).copyWith(name: name);
    await saveDay(uid, programId, copy);
    return copy;
  }

  @override
  Future<void> archive(String uid, Program program) async {
    await saveProgram(
      uid,
      program.copyWith(
        status: ProgramStatus.archived,
        updatedAt: DateTime.now().toUtc(),
      ),
    );

    final profile = profiles?.profiles[uid];
    if (program.isActive && profile != null) {
      await profiles!.save(uid, profile.copyWith(activeProgramId: null));
    }
  }

  @override
  Future<void> activate(
    String uid, {
    required String programId,
    String? demote,
  }) async {
    final now = DateTime.now().toUtc();
    final owned = [
      for (final program in [...?programs[uid]])
        if (program.id == programId)
          program.copyWith(status: ProgramStatus.active, updatedAt: now)
        else if (program.id == demote)
          program.copyWith(status: ProgramStatus.draft, updatedAt: now)
        else
          program,
    ];
    programs[uid] = owned;
    _emitPrograms(uid);

    final profile = profiles?.profiles[uid];
    if (profile != null) {
      await profiles!.save(uid, profile.copyWith(activeProgramId: programId));
    }
  }

  Day _withFreshIds(Day day) => day.copyWith(
    id: newId('day'),
    blocks: [
      for (final block in day.blocks) block.copyWith(blockId: newId('block')),
    ],
  );

  void _emitPrograms(String uid) =>
      _programControllerFor(uid).add(_sortedPrograms(uid));

  void _emitDays(String uid, String programId) =>
      _dayControllerFor(_key(uid, programId)).add(_sortedDays(uid, programId));

  Future<void> dispose() async {
    for (final controller in _programControllers.values) {
      await controller.close();
    }
    for (final controller in _dayControllers.values) {
      await controller.close();
    }
  }
}
