import 'package:mesa/domain/models/exercise.dart';

/// User-created exercises: `users/{uid}/customExercises/{exerciseId}` (§4, F2).
///
/// Same shape as a catalogue [Exercise], distinguished by
/// [ExerciseSource.custom], so search can merge the two into one list.
abstract interface class CustomExerciseRepository {
  /// Watches every custom exercise the user owns.
  ///
  /// Backed by the offline cache, so it emits without connectivity (NFR1).
  Stream<List<Exercise>> watch(String uid);

  /// Creates or replaces one. The exercise's `id` is the document id.
  Future<void> save(String uid, Exercise exercise);

  Future<void> delete(String uid, String exerciseId);
}
