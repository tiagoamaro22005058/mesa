import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesa/data/catalog/bundled_exercise_catalog.dart';
import 'package:mesa/data/catalog/exercise_search_index.dart';
import 'package:mesa/data/firestore/firestore_custom_exercise_repository.dart';
import 'package:mesa/domain/models/exercise.dart';
import 'package:mesa/domain/models/exercise_filter.dart';
import 'package:mesa/domain/repositories/custom_exercise_repository.dart';
import 'package:mesa/domain/repositories/exercise_catalog.dart';
import 'package:mesa/features/auth/providers/auth_providers.dart';
import 'package:mesa/features/settings/providers/profile_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'catalog_providers.g.dart';

/// The bundled catalogue asset.
///
/// Overridden with a fake in widget tests, which is what keeps them off
/// `rootBundle` and off a 1.1 MB parse per test.
@Riverpod(keepAlive: true)
ExerciseCatalog exerciseCatalog(Ref ref) => BundledExerciseCatalog();

/// `users/{uid}/customExercises` (§4).
@Riverpod(keepAlive: true)
CustomExerciseRepository customExerciseRepository(Ref ref) =>
    FirestoreCustomExerciseRepository(FirebaseFirestore.instance);

/// The 1,295 bundled exercises, parsed once per app session.
///
/// `keepAlive` because the parse is the expensive part and the data never
/// changes — leaving the catalogue screen and coming back must not re-read the
/// asset. Nothing reads this until something asks for the catalogue, so cold
/// start is untouched (NFR3).
@Riverpod(keepAlive: true)
Future<List<Exercise>> bundledExercises(Ref ref) =>
    ref.watch(exerciseCatalogProvider).load();

/// The signed-in user's own exercises, or empty when signed out.
@riverpod
Stream<List<Exercise>> customExercises(Ref ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(const []);

  return ref.watch(customExerciseRepositoryProvider).watch(uid);
}

/// Catalogue and custom exercises, merged and indexed for search (F2).
///
/// Rebuilt when the custom list changes — 1,295 normalisations take a few
/// milliseconds, and a custom exercise has to be searchable the moment it is
/// created.
@riverpod
Future<ExerciseSearchIndex> exerciseIndex(Ref ref) async {
  final bundled = await ref.watch(bundledExercisesProvider.future);
  final custom = ref.watch(customExercisesProvider).value ?? const <Exercise>[];

  return ExerciseSearchIndex([...bundled, ...custom]);
}

/// What is in the search box. Held here rather than in the widget so the
/// results provider can depend on it.
@riverpod
class CatalogQuery extends _$CatalogQuery {
  @override
  String build() => '';

  // ignore: use_setters_to_change_properties
  void update(String query) => state = query;
}

/// Which body part, muscle and equipment the list is narrowed to (F2).
@riverpod
class CatalogFilter extends _$CatalogFilter {
  @override
  ExerciseFilter build() => ExerciseFilter.none;

  void update(ExerciseFilter filter) => state = filter;

  void clear() => state = ExerciseFilter.none;
}

/// The ids the user starred (F2).
///
/// Read off the profile document, which is already being streamed for every
/// other setting — favourites cost no extra read (NFR2).
@riverpod
Set<String> favouriteExerciseIds(Ref ref) {
  final profile = ref.watch(userProfileProvider).value;
  return profile?.favouriteExerciseIds.toSet() ?? const {};
}

/// What the catalogue screen shows: the query and filters applied to the index.
@riverpod
Future<List<Exercise>> catalogResults(Ref ref) async {
  final index = await ref.watch(exerciseIndexProvider.future);

  return index.search(
    ref.watch(catalogQueryProvider),
    filter: ref.watch(catalogFilterProvider),
    favouriteIds: ref.watch(favouriteExerciseIdsProvider),
  );
}

/// One exercise by id, from the merged catalogue.
///
/// Returns `null` when it does not exist, which is what a deep link to a
/// deleted custom exercise produces.
@riverpod
Future<Exercise?> exerciseById(Ref ref, String id) async {
  final bundled = await ref.watch(bundledExercisesProvider.future);
  final custom = ref.watch(customExercisesProvider).value ?? const <Exercise>[];

  // Custom first: a user-created exercise that happens to share an id with a
  // catalogue one is the one the user made, and the one they can edit.
  for (final exercise in [...custom, ...bundled]) {
    if (exercise.id == id) return exercise;
  }
  return null;
}

/// Creates, edits and deletes custom exercises, and toggles favourites (F2).
///
/// `keepAlive`, unlike `AuthController` and `ProfileController`. Those are
/// watched by the screen that drives them, which keeps them alive for as long
/// as their work takes. This one is called from a list row and from a
/// confirmation dialog — nothing watches it — so an auto-disposed version is
/// disposed at its first `await`, and every `ref.read` after that point runs
/// against a dead `Ref`. `AsyncValue.guard` then swallows the error, and the
/// second half of a two-step action silently does not happen.
@Riverpod(keepAlive: true)
class CatalogController extends _$CatalogController {
  @override
  FutureOr<void> build() {}

  Future<void> saveCustomExercise(Exercise exercise) async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    await _run(() => ref.read(customExerciseRepositoryProvider).save(uid, exercise));
  }

  Future<void> deleteCustomExercise(String exerciseId) async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    // Read before deleting, not after. The delete makes the exercise vanish
    // from the merged catalogue, which sends the detail screen to its
    // "no longer exists" state and disposes the widget keeping
    // `userProfileProvider` alive — so a read on the far side of the await
    // gets a freshly-created provider with no value yet, and the unstar
    // silently never happens.
    final profile = ref.read(userProfileProvider).value;

    await _run(() async {
      await ref.read(customExerciseRepositoryProvider).delete(uid, exerciseId);

      // A deleted exercise that is still starred would leave the favourites
      // filter showing a row that resolves to nothing.
      if (profile != null && profile.isFavourite(exerciseId)) {
        await ref.read(profileControllerProvider.notifier).save(
          profile.toggleFavourite(exerciseId),
        );
      }
    });
  }

  /// Stars or unstars an exercise.
  ///
  /// Writes through the profile controller rather than its own path, so there
  /// is one place that stamps `updatedAt` on the profile document.
  Future<void> toggleFavourite(String exerciseId) async {
    final profile = ref.read(userProfileProvider).value;
    if (profile == null) return;

    await _run(
      () => ref
          .read(profileControllerProvider.notifier)
          .save(profile.toggleFavourite(exerciseId)),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);

    // Deleting an exercise pops the screen watching this controller, which
    // disposes it. Writing state afterwards would throw on a dead Ref.
    if (!ref.mounted) return;
    state = result;
  }
}

/// The next id for a user-created exercise.
///
/// Deliberately not a 4-digit number: catalogue ids are upstream's and look
/// like `0043`, so a custom one that looked the same could collide with a
/// future catalogue entry and silently shadow it.
String newCustomExerciseId() => 'custom-${DateTime.now().microsecondsSinceEpoch}';
