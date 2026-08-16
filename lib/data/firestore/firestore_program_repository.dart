import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesa/core/failures/firestore_failure.dart';
import 'package:mesa/core/ids.dart';
import 'package:mesa/data/firestore/converters/day_converter.dart';
import 'package:mesa/data/firestore/converters/program_converter.dart';
import 'package:mesa/data/firestore/firestore_failure_mapper.dart';
import 'package:mesa/domain/models/day.dart';
import 'package:mesa/domain/models/program.dart';
import 'package:mesa/domain/repositories/program_repository.dart';

/// [ProgramRepository] backed by `users/{uid}/programs` (§4).
class FirestoreProgramRepository implements ProgramRepository {
  FirestoreProgramRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const String usersCollection = 'users';
  static const String programsCollection = 'programs';
  static const String daysCollection = 'days';

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection(usersCollection).doc(uid);

  CollectionReference<Map<String, dynamic>> _programs(String uid) =>
      _userDoc(uid).collection(programsCollection);

  CollectionReference<Map<String, dynamic>> _days(String uid, String programId) =>
      _programs(uid).doc(programId).collection(daysCollection);

  @override
  Stream<List<Program>> watchPrograms(String uid) {
    return _programs(uid).snapshots().map((snapshot) {
      final programs = [
        for (final document in snapshot.docs)
          ProgramConverter.fromMap(document.id, document.data()),
      ];
      // Sorted here rather than with orderBy: a user has a handful of programs,
      // and a query that sorts server-side needs an index and a round trip,
      // while this works identically against the offline cache (NFR1, NFR2).
      programs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return programs;
    }).handleError(
      (Object error) => throw FirestoreFailureMapper.from(error as FirebaseException),
      test: (error) => error is FirebaseException,
    );
  }

  @override
  Stream<List<Day>> watchDays(String uid, String programId) {
    return _days(uid, programId).snapshots().map((snapshot) {
      final days = [
        for (final document in snapshot.docs)
          DayConverter.fromMap(document.id, document.data()),
      ];
      days.sort((a, b) => a.order.compareTo(b.order));
      return days;
    }).handleError(
      (Object error) => throw FirestoreFailureMapper.from(error as FirebaseException),
      test: (error) => error is FirebaseException,
    );
  }

  @override
  Future<void> saveProgram(String uid, Program program) async {
    // Deliberately not awaited, like every other write in the app: Firestore
    // completes a write's future only when the server acknowledges it, so
    // awaiting hangs with no connectivity (NFR1) and costs a round trip with it
    // (NFR3). The local cache applies it synchronously and the watchers re-emit
    // from there, so the UI updates either way.
    unawaited(
      _programs(uid).doc(program.id).set(ProgramConverter.toMap(program)),
    );
  }

  @override
  Future<void> saveDay(String uid, String programId, Day day) async {
    unawaited(_days(uid, programId).doc(day.id).set(DayConverter.toMap(day)));
  }

  @override
  Future<void> deleteDay(String uid, String programId, String dayId) async {
    unawaited(_days(uid, programId).doc(dayId).delete());
  }

  @override
  Future<void> reorderDays(String uid, String programId, List<Day> days) async {
    final batch = _firestore.batch();

    for (final (index, day) in days.indexed) {
      if (day.order == index) continue;
      // Merged, not replaced: this must not touch the blocks embedded in the
      // day, which are not in hand here and are the bulk of the document.
      batch.set(
        _days(uid, programId).doc(day.id),
        <String, dynamic>{'order': index},
        SetOptions(merge: true),
      );
    }

    unawaited(batch.commit());
  }

  @override
  Future<String> duplicateProgram(
    String uid,
    String programId, {
    required String name,
  }) async {
    // These two reads are awaited, unlike the writes. `get()` falls back to the
    // offline cache when the server is unreachable, so it completes either way
    // rather than hanging (NFR1) — a duplicate has to read what it is copying.
    final source = await _programs(uid).doc(programId).get();
    final data = source.data();
    if (data == null) {
      throw const FirestoreFailure(FirestoreFailureKind.notFound);
    }

    final days = await _days(uid, programId).get();

    final now = DateTime.now().toUtc();
    final copyId = newId('program');
    final copy = ProgramConverter.fromMap(programId, data).copyWith(
      id: copyId,
      name: name,
      // A copy is never active. Exactly one program may be (F3), and silently
      // making the copy active would displace the program being copied.
      status: ProgramStatus.draft,
      createdAt: now,
      updatedAt: now,
    );

    final batch = _firestore.batch();
    batch.set(_programs(uid).doc(copyId), ProgramConverter.toMap(copy));

    for (final document in days.docs) {
      final dayCopy = _withFreshIds(
        DayConverter.fromMap(document.id, document.data()),
      );
      batch.set(_days(uid, copyId).doc(dayCopy.id), DayConverter.toMap(dayCopy));
    }

    unawaited(batch.commit());
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
    final batch = _firestore.batch();
    final now = Timestamp.fromDate(DateTime.now().toUtc());

    batch.set(
      _programs(uid).doc(program.id),
      <String, dynamic>{'status': ProgramStatus.archived.wireValue, 'updatedAt': now},
      SetOptions(merge: true),
    );

    // Only when this program held the slot. Clearing unconditionally would
    // unset a pointer aimed at some other, still-active program.
    if (program.isActive) {
      batch.set(
        _userDoc(uid),
        <String, dynamic>{'activeProgramId': null, 'updatedAt': now},
        SetOptions(merge: true),
      );
    }

    unawaited(batch.commit());
  }

  @override
  Future<void> activate(
    String uid, {
    required String programId,
    String? demote,
  }) async {
    final batch = _firestore.batch();
    final now = Timestamp.fromDate(DateTime.now().toUtc());

    if (demote != null && demote != programId) {
      batch.set(
        _programs(uid).doc(demote),
        <String, dynamic>{'status': ProgramStatus.draft.wireValue, 'updatedAt': now},
        SetOptions(merge: true),
      );
    }

    batch.set(
      _programs(uid).doc(programId),
      <String, dynamic>{'status': ProgramStatus.active.wireValue, 'updatedAt': now},
      SetOptions(merge: true),
    );

    // §4 keeps the active program in two places. Written here, in the same
    // batch, so they cannot drift — see the interface for why this repository
    // is the one that touches the profile document.
    batch.set(
      _userDoc(uid),
      <String, dynamic>{'activeProgramId': programId, 'updatedAt': now},
      SetOptions(merge: true),
    );

    unawaited(batch.commit());
  }

  /// A copy of [day] whose day id and every block id are new.
  ///
  /// Reusing them would give one program two blocks with the same `blockId`,
  /// and M4's `SetLog.blockId` no way to say which one a set belonged to.
  Day _withFreshIds(Day day) => day.copyWith(
    id: newId('day'),
    blocks: [
      for (final block in day.blocks) block.copyWith(blockId: newId('block')),
    ],
  );
}
