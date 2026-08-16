import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesa/core/ids.dart';
import 'package:mesa/data/firestore/firestore_program_repository.dart';
import 'package:mesa/domain/models/block.dart';
import 'package:mesa/domain/models/day.dart';
import 'package:mesa/domain/models/program.dart';
import 'package:mesa/domain/repositories/program_repository.dart';
import 'package:mesa/features/auth/providers/auth_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'program_providers.g.dart';

/// `users/{uid}/programs` and the days beneath it (§4).
@Riverpod(keepAlive: true)
ProgramRepository programRepository(Ref ref) =>
    FirestoreProgramRepository(FirebaseFirestore.instance);

/// Every program the user owns, or empty when signed out.
@riverpod
Stream<List<Program>> programs(Ref ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(const []);

  return ref.watch(programRepositoryProvider).watchPrograms(uid);
}

/// One program by id.
///
/// Derived from [programsProvider] rather than opening a second listener: the
/// list is already streamed and a user has a handful of programs, so filtering
/// it costs nothing and saves a read (NFR2). Returns `null` when the program
/// does not exist, which is what a deep link to a deleted one produces.
@riverpod
Program? programById(Ref ref, String programId) {
  final programs = ref.watch(programsProvider).value ?? const <Program>[];

  for (final program in programs) {
    if (program.id == programId) return program;
  }
  return null;
}

/// One program's day templates, in order.
@riverpod
Stream<List<Day>> programDays(Ref ref, String programId) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(const []);

  return ref.watch(programRepositoryProvider).watchDays(uid, programId);
}

/// One day by id, from the program's already-streamed list.
@riverpod
Day? dayById(Ref ref, String programId, String dayId) {
  final days = ref.watch(programDaysProvider(programId)).value ?? const <Day>[];

  for (final day in days) {
    if (day.id == dayId) return day;
  }
  return null;
}

/// The program currently marked active, if there is one (F3).
@riverpod
Program? activeProgram(Ref ref) {
  final programs = ref.watch(programsProvider).value ?? const <Program>[];

  for (final program in programs) {
    if (program.isActive) return program;
  }
  return null;
}

/// Builds and edits programs, days and blocks (F3).
///
/// `keepAlive`, for the reason `CatalogController` documents: this is called
/// from list rows and confirmation dialogs, which nothing watches, so an
/// auto-disposed version is disposed at its first `await` and every `ref.read`
/// after that point runs against a dead `Ref`.
@Riverpod(keepAlive: true)
class ProgramController extends _$ProgramController {
  @override
  FutureOr<void> build() {}

  /// Creates a program and returns it, so the caller can navigate to it.
  ///
  /// Returns `null` when signed out, which the screens treat as "do nothing"
  /// rather than as an error — it only happens if the session ends mid-form.
  Future<Program?> createProgram({
    required String name,
    String? goal,
    int daysPerWeek = Program.defaultDaysPerWeek,
  }) async {
    final uid = _uid;
    if (uid == null) return null;

    final now = DateTime.now().toUtc();
    final program = Program(
      id: newId('program'),
      name: name,
      goal: goal,
      daysPerWeek: daysPerWeek,
      createdAt: now,
      updatedAt: now,
    );

    await _run(() => ref.read(programRepositoryProvider).saveProgram(uid, program));
    return program;
  }

  /// Saves an edited program, stamping `updatedAt`.
  ///
  /// One place stamps it, the way the profile controller is the only thing that
  /// stamps the profile's — otherwise every screen has its own opinion about
  /// whether an edit counts as an update.
  Future<void> saveProgram(Program program) async {
    final uid = _uid;
    if (uid == null) return;

    await _run(
      () => ref
          .read(programRepositoryProvider)
          .saveProgram(uid, program.copyWith(updatedAt: DateTime.now().toUtc())),
    );
  }

  /// Retires a program, clearing the profile's pointer when it held it.
  ///
  /// Both writes go through the repository in one batch rather than being
  /// stitched together here. An earlier version read `userProfileProvider` to
  /// decide, which silently did nothing: no screen in this feature watches the
  /// profile, so the provider was created on the spot and its first value had
  /// not arrived — the same trap `CatalogController.deleteCustomExercise`
  /// documents.
  Future<void> archiveProgram(Program program) async {
    final uid = _uid;
    if (uid == null) return;

    await _run(() => ref.read(programRepositoryProvider).archive(uid, program));
  }

  /// Makes [program] the one active program, demoting whichever held it (F3).
  Future<void> activateProgram(Program program) async {
    final uid = _uid;
    if (uid == null) return;

    final current = ref.read(activeProgramProvider);

    await _run(
      () => ref.read(programRepositoryProvider).activate(
        uid,
        programId: program.id,
        demote: current?.id,
      ),
    );
  }

  /// Deep-copies a program as a fresh draft. Returns the copy's id.
  Future<String?> duplicateProgram(Program program, {required String name}) async {
    final uid = _uid;
    if (uid == null) return null;

    String? copyId;
    await _run(() async {
      copyId = await ref
          .read(programRepositoryProvider)
          .duplicateProgram(uid, program.id, name: name);
    });
    return copyId;
  }

  Future<void> saveDay(String programId, Day day) async {
    final uid = _uid;
    if (uid == null) return;

    await _run(() async {
      await ref.read(programRepositoryProvider).saveDay(uid, programId, day);
      await _touch(programId);
    });
  }

  /// Appends a new, empty day to the end of the program.
  Future<Day?> addDay(String programId, String name) async {
    final uid = _uid;
    if (uid == null) return null;

    final existing = ref.read(programDaysProvider(programId)).value ?? const <Day>[];
    final day = Day(id: newId('day'), name: name, order: existing.length);

    await saveDay(programId, day);
    return day;
  }

  Future<void> deleteDay(String programId, String dayId) async {
    final uid = _uid;
    if (uid == null) return;

    await _run(() async {
      await ref.read(programRepositoryProvider).deleteDay(uid, programId, dayId);
      await _touch(programId);
    });
  }

  Future<void> reorderDays(String programId, List<Day> days) async {
    final uid = _uid;
    if (uid == null) return;

    await _run(() async {
      await ref.read(programRepositoryProvider).reorderDays(uid, programId, days);
      await _touch(programId);
    });
  }

  Future<Day?> duplicateDay(String programId, Day day, {required String name}) async {
    final uid = _uid;
    if (uid == null) return null;

    Day? copy;
    await _run(() async {
      copy = await ref
          .read(programRepositoryProvider)
          .duplicateDay(uid, programId, day, name: name);
      await _touch(programId);
    });
    return copy;
  }

  /// Adds or replaces a block within a day.
  ///
  /// Blocks are embedded in the day document (§4.1), so every block edit is a
  /// day write — there is no separate block path to save to.
  Future<void> saveBlock(String programId, Day day, Block block) async {
    final blocks = [...day.blocks];
    final index = blocks.indexWhere((b) => b.blockId == block.blockId);

    if (index == -1) {
      blocks.add(block);
    } else {
      blocks[index] = block;
    }

    await saveDay(programId, day.copyWith(blocks: blocks));
  }

  Future<void> deleteBlock(String programId, Day day, String blockId) async {
    final blocks = [...day.blocks]..removeWhere((b) => b.blockId == blockId);

    await saveDay(programId, day.copyWith(blocks: blocks));
  }

  /// Persists a drag. The list order *is* the block order (§4's `order` field
  /// is written from the index and never read back as the source of truth).
  Future<void> reorderBlocks(String programId, Day day, List<Block> blocks) async {
    await saveDay(programId, day.copyWith(blocks: blocks));
  }

  String? get _uid => ref.read(authStateProvider).value?.uid;

  /// Stamps the program's `updatedAt` after a change to one of its days.
  ///
  /// Days carry no timestamps of their own (§4), so without this the program
  /// list would sort a heavily-edited program below one nobody has touched.
  Future<void> _touch(String programId) async {
    final uid = _uid;
    final program = ref.read(programByIdProvider(programId));
    if (uid == null || program == null) return;

    await ref
        .read(programRepositoryProvider)
        .saveProgram(uid, program.copyWith(updatedAt: DateTime.now().toUtc()));
  }

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);

    // Deleting a day pops the screen watching this controller, which disposes
    // it. Writing state afterwards would throw on a dead Ref.
    if (!ref.mounted) return;
    state = result;
  }
}
