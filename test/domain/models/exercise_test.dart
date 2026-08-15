import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/domain/models/equipment.dart';
import 'package:mesa/domain/models/load_model.dart';
import 'package:mesa/domain/models/muscle.dart';

import '../../support/exercises.dart';

void main() {
  group('copyWith', () {
    test('leaves omitted fields alone', () {
      final original = exercise('0025', 'barbell bench press', synergist: Muscle.triceps);

      final updated = original.copyWith(name: 'barbell incline bench press');

      expect(updated.name, 'barbell incline bench press');
      expect(updated.id, '0025');
      expect(updated.synergist, Muscle.triceps);
    });

    test('can clear a nullable field, not only replace it', () {
      // The failure mode a hand-written copyWith has by default: a plain
      // nullable parameter cannot tell "leave this alone" from "set to null",
      // and an optional field that cannot be cleared is the bug that produces
      // (§2). Every nullable field on this model uses the sentinel.
      final original = exercise(
        '0025',
        'barbell bench press',
        synergist: Muscle.triceps,
        thumbnailUrl: 'https://example.test/a.jpg',
        gifUrl: 'https://example.test/a.gif',
      );

      final cleared = original.copyWith(
        synergist: null,
        thumbnailUrl: null,
        gifUrl: null,
        attribution: null,
      );

      expect(cleared.synergist, isNull);
      expect(cleared.thumbnailUrl, isNull);
      expect(cleared.gifUrl, isNull);
      expect(cleared.attribution, isNull);
      expect(cleared.name, 'barbell bench press');
    });
  });

  group('equality', () {
    test('compares lists by value, not identity', () {
      // An exercise decoded twice from the same JSON holds different list
      // objects with the same contents.
      final a = exercise('0025', 'bench', aliases: ['supino'], secondaryMuscles: [Muscle.triceps]);
      final b = exercise('0025', 'bench', aliases: ['supino'], secondaryMuscles: [Muscle.triceps]);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('distinguishes a custom exercise from a catalogue one', () {
      final catalogue = exercise('x', 'my press');
      final custom = customExercise('x', 'my press');

      expect(catalogue, isNot(custom));
      expect(custom.isCustom, isTrue);
      expect(catalogue.isCustom, isFalse);
    });

    test('notices a changed list element', () {
      final a = exercise('0025', 'bench', secondaryMuscles: [Muscle.triceps]);
      final b = exercise('0025', 'bench', secondaryMuscles: [Muscle.delts]);

      expect(a, isNot(b));
    });
  });

  group('wire values', () {
    test('every enum round-trips through its wire value', () {
      // The wire values are fixed by §4 and §5.4 and are what sits in the
      // asset and in Firestore. Deriving them from `name` would let a rename
      // rewrite stored data.
      for (final muscle in Muscle.values) {
        expect(Muscle.tryFromWire(muscle.wireValue), muscle);
      }
      for (final equipment in Equipment.values) {
        expect(Equipment.tryFromWire(equipment.wireValue), equipment);
      }
      for (final model in LoadModel.values) {
        expect(LoadModel.tryFromWire(model.wireValue), model);
      }
    });

    test('returns null for a value that is not ours', () {
      // Nullable rather than defaulting: an unrecognised muscle means either a
      // corrupt asset or tables ahead of the enums, and each caller decides how
      // loudly to fail.
      expect(Muscle.tryFromWire('pectorals'), isNull);
      expect(Muscle.tryFromWire(null), isNull);
      expect(Equipment.tryFromWire('gravity boots'), isNull);
    });
  });

  group('equipment', () {
    test('derives the load models §5.6 specifies', () {
      expect(Equipment.barbell.defaultLoadModel, LoadModel.externalLoad);
      expect(Equipment.bodyWeight.defaultLoadModel, LoadModel.bodyweight);
      expect(Equipment.weighted.defaultLoadModel, LoadModel.bodyweightPlusLoad);
      expect(Equipment.assisted.defaultLoadModel, LoadModel.assisted);
    });

    test('carries §4 gym tags, and admits when there is none', () {
      expect(Equipment.ezBarbell.gymTag, GymEquipmentTag.barbell);
      expect(Equipment.kettlebell.gymTag, GymEquipmentTag.dumbbell);
      expect(Equipment.smithMachine.gymTag, GymEquipmentTag.smith);
      // A stability ball is neither a machine nor bodyweight, and §4's seven
      // tags cannot say so. Substitution will never flag these as missing.
      expect(Equipment.other.gymTag, isNull);
      expect(Equipment.medicineBall.gymTag, isNull);
    });
  });
}
