import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesa/data/firestore/converters/custom_exercise_converter.dart';
import 'package:mesa/data/firestore/firestore_failure_mapper.dart';
import 'package:mesa/domain/models/exercise.dart';
import 'package:mesa/domain/repositories/custom_exercise_repository.dart';

/// [CustomExerciseRepository] backed by `users/{uid}/customExercises` (§4).
class FirestoreCustomExerciseRepository implements CustomExerciseRepository {
  FirestoreCustomExerciseRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const String usersCollection = 'users';
  static const String customExercisesCollection = 'customExercises';

  CollectionReference<Map<String, dynamic>> _collection(String uid) => _firestore
      .collection(usersCollection)
      .doc(uid)
      .collection(customExercisesCollection);

  @override
  Stream<List<Exercise>> watch(String uid) {
    return _collection(uid).snapshots().map((snapshot) {
      final exercises = [
        for (final document in snapshot.docs)
          CustomExerciseConverter.fromMap(document.id, document.data()),
      ];
      // Sorted here rather than with orderBy: the list is small, and a query
      // that sorts server-side needs an index and a round trip, while this
      // works identically against the offline cache (NFR1, NFR2).
      exercises.sort((a, b) => a.name.compareTo(b.name));
      return exercises;
    }).handleError(
      (Object error) => throw FirestoreFailureMapper.from(error as FirebaseException),
      test: (error) => error is FirebaseException,
    );
  }

  @override
  Future<void> save(String uid, Exercise exercise) async {
    // Deliberately not awaited, like every other write in the app: Firestore
    // completes a write's future only when the server acknowledges it, so
    // awaiting hangs with no connectivity (NFR1) and costs a round trip with it
    // (NFR3). The local cache applies it synchronously and watch() re-emits
    // from there, so the list updates either way.
    unawaited(
      _collection(uid).doc(exercise.id).set(CustomExerciseConverter.toMap(exercise)),
    );
  }

  @override
  Future<void> delete(String uid, String exerciseId) async {
    unawaited(_collection(uid).doc(exerciseId).delete());
  }
}
