import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/data/firestore/converters/custom_exercise_converter.dart';
import 'package:mesa/data/firestore/firestore_failure_mapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesa/core/failures/firestore_failure.dart';
import 'package:mesa/domain/models/body_part.dart';
import 'package:mesa/domain/models/equipment.dart';
import 'package:mesa/domain/models/exercise.dart';
import 'package:mesa/domain/models/load_model.dart';
import 'package:mesa/domain/models/muscle.dart';

import '../../support/exercises.dart';

void main() {
  group('CustomExerciseConverter', () {
    test('round-trips an exercise the user created', () {
      final original = customExercise(
        'custom-1',
        'my gym chest press',
        bodyPart: BodyPart.chest,
        primaryMuscle: Muscle.chest,
        equipment: Equipment.leverageMachine,
        steps: const ['Sit down.', 'Press.'],
      );

      final restored = CustomExerciseConverter.fromMap(
        'custom-1',
        CustomExerciseConverter.toMap(original),
      );

      expect(restored, original);
    });

    test('marks everything it reads as custom', () {
      final restored = CustomExerciseConverter.fromMap('custom-1', {'name': 'my press'});

      expect(restored.source, ExerciseSource.custom);
      expect(restored.isCustom, isTrue);
    });

    test('derives the load model from equipment rather than reading it back', () {
      // §5.6 makes the load model the thing the M5 maths turns on, and it is a
      // function of equipment. Storing it separately only creates a way for the
      // two to disagree — so a stored value is ignored outright.
      final restored = CustomExerciseConverter.fromMap('custom-1', {
        'name': 'weighted chin-up',
        'equipment': 'weighted',
        'loadModel': 'externalLoad',
      });

      expect(restored.loadModel, LoadModel.bodyweightPlusLoad);
      expect(CustomExerciseConverter.toMap(restored).containsKey('loadModel'), isFalse);
    });

    test('falls back to a visible default rather than throwing', () {
      // Deliberately unlike the catalogue converter. The rules authenticate but
      // do not validate (§4.3), and an exercise that refuses to parse would
      // take a program's blocks down with it in M3.
      final restored = CustomExerciseConverter.fromMap('custom-1', {
        'name': 'mystery lift',
        'primaryMuscle': 'gluteus profundus',
        'equipment': 'gravity boots',
        'bodyPart': 'tail',
      });

      expect(restored.primaryMuscle, Muscle.other);
      expect(restored.equipment, Equipment.other);
      expect(restored.bodyPart, BodyPart.waist);
      expect(restored.name, 'mystery lift');
    });

    test('survives a document with almost nothing in it', () {
      final restored = CustomExerciseConverter.fromMap('custom-1', const {});

      expect(restored.id, 'custom-1');
      expect(restored.name, '');
      expect(restored.steps, isEmpty);
      expect(restored.secondaryMuscles, isEmpty);
    });

    test('keeps no attribution — there is no borrowed media to credit', () {
      // §5.1 covers Gym visual's images. A user-created exercise has none.
      final restored = CustomExerciseConverter.fromMap('custom-1', {'name': 'my press'});

      expect(restored.attribution, isNull);
      expect(restored.thumbnailUrl, isNull);
      expect(restored.gifUrl, isNull);
    });
  });

  group('FirestoreFailureMapper', () {
    test('maps the codes worth telling apart', () {
      expect(
        FirestoreFailureMapper.from(FirebaseException(plugin: 'firestore', code: 'permission-denied')),
        const FirestoreFailure(FirestoreFailureKind.permissionDenied),
      );
      expect(
        FirestoreFailureMapper.from(FirebaseException(plugin: 'firestore', code: 'not-found')),
        const FirestoreFailure(FirestoreFailureKind.notFound),
      );
    });

    test('keeps the original code on an unmapped failure', () {
      // §9.1: an unmapped failure has to stay diagnosable from a bug report
      // rather than vanishing into a generic message.
      final failure = FirestoreFailureMapper.from(
        FirebaseException(plugin: 'firestore', code: 'resource-exhausted'),
      );

      expect(failure.kind, FirestoreFailureKind.unknown);
      expect(failure.code, 'resource-exhausted');
    });
  });
}
