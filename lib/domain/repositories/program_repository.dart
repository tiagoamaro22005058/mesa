import 'package:mesa/domain/models/day.dart';
import 'package:mesa/domain/models/program.dart';

/// Programs and their day templates: `users/{uid}/programs/{programId}` and the
/// `days` subcollection beneath it (§4, F3).
///
/// Every method throws a [FirestoreFailure](../../core/failures/firestore_failure.dart)
/// on failure rather than returning a result type, so a caller can wrap a whole
/// flow in one `try`/`catch`.
abstract interface class ProgramRepository {
  /// Watches every program the user owns, most recently updated first.
  ///
  /// Backed by the offline cache, so it emits without connectivity (NFR1).
  Stream<List<Program>> watchPrograms(String uid);

  /// Watches one program's day templates, in [Day.order].
  Stream<List<Day>> watchDays(String uid, String programId);

  /// Creates or replaces a program. The program's `id` is the document id.
  Future<void> saveProgram(String uid, Program program);

  /// Creates or replaces a day, blocks and all — they are embedded in the
  /// document rather than a subcollection (§4.1), so adding, editing,
  /// reordering and removing a block all come through here.
  Future<void> saveDay(String uid, String programId, Day day);

  Future<void> deleteDay(String uid, String programId, String dayId);

  /// Renumbers [days] to their position in the list.
  ///
  /// Only the days whose order actually moved are written.
  Future<void> reorderDays(String uid, String programId, List<Day> days);

  /// Deep-copies a program and every day in it, as a fresh draft.
  ///
  /// Returns the new program's id. Days and blocks get new ids of their own —
  /// sharing a `blockId` with the original would leave M4 unable to say which
  /// program a logged set belonged to.
  Future<String> duplicateProgram(String uid, String programId, {required String name});

  /// Copies [day] within its program, appended at the end. Returns the copy.
  Future<Day> duplicateDay(String uid, String programId, Day day, {required String name});

  /// Retires [program] (F3), clearing `users/{uid}.activeProgramId` when it is
  /// the one the profile points at.
  ///
  /// Batched with the same reasoning as [activate]: §4 stores the active
  /// program in two places, so any write that changes it has to write both or
  /// leave M4 starting sessions from a program the user retired.
  ///
  /// Whether to clear is read off [Program.status] rather than off the profile.
  /// [activate] is the only thing that sets either, and it sets them together,
  /// so `status == active` already means the profile points here — and reading
  /// the profile to re-derive that would need a listener this call does not
  /// have.
  Future<void> archive(String uid, Program program);

  /// Makes [programId] the one active program (F3).
  ///
  /// Writes three documents in a **single batch**: the newly active program,
  /// the one it displaces (`demote`, dropped back to draft — it was never
  /// archived, and archiving on the user's behalf is a destructive act NFR5
  /// would want confirmed), and `users/{uid}.activeProgramId`.
  ///
  /// §4 stores the active program in both places, so the only safe way to write
  /// them is together. A batch applies to the local cache atomically and syncs
  /// later, which keeps that true offline (NFR1).
  ///
  /// This is the one place a repository writes outside its own collection. The
  /// alternative — splitting the write across [ProgramRepository] and
  /// `UserProfileRepository` to keep the boundary tidy — would destroy the
  /// atomicity that is the entire point of the method.
  Future<void> activate(String uid, {required String programId, String? demote});
}
