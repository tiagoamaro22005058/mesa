import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/domain/models/unit_system.dart';
import 'package:mesa/domain/models/user_profile.dart';

void main() {
  final now = DateTime.utc(2026, 8, 15);

  group('UserProfile defaults', () {
    test('match §4 exactly', () {
      final profile = UserProfile(
        displayName: 'Tiago',
        createdAt: now,
        updatedAt: now,
      );

      expect(profile.units, UnitSystem.kg);
      expect(profile.barWeight, 20);
      expect(profile.plateInventory, [25, 20, 15, 10, 5, 2.5, 1.25]);
      expect(profile.dumbbellIncrement, 2);
    });

    test('leave the active program and gym unset until M3 and M7 fill them', () {
      final profile = UserProfile(
        displayName: 'Tiago',
        createdAt: now,
        updatedAt: now,
      );

      expect(profile.activeProgramId, isNull);
      expect(profile.activeGymId, isNull);
    });
  });

  group('UserProfile equality', () {
    UserProfile build({List<double>? plates, String? programId}) => UserProfile(
      displayName: 'Tiago',
      createdAt: now,
      updatedAt: now,
      plateInventory: plates ?? UserProfile.defaultPlateInventory,
      activeProgramId: programId,
    );

    test('compares the plate inventory by value, not by identity', () {
      // A profile read back from Firestore holds a different list object with
      // the same plates in it; comparing by identity would call every reload a
      // change.
      expect(build(plates: [20, 10]), build(plates: [20, 10]));
      expect(build(plates: [20, 10]).hashCode, build(plates: [20, 10]).hashCode);
    });

    test('notices a changed plate inventory', () {
      expect(build(plates: [20, 10]), isNot(build(plates: [20, 10, 5])));
    });

    test('notices a changed optional field', () {
      expect(build(programId: 'p1'), isNot(build()));
    });
  });

  group('UserProfile.copyWith', () {
    final profile = UserProfile(
      displayName: 'Tiago',
      createdAt: now,
      updatedAt: now,
      activeProgramId: 'program-1',
      activeGymId: 'gym-1',
    );

    test('leaves untouched fields alone', () {
      final updated = profile.copyWith(displayName: 'Tiago A');

      expect(updated.displayName, 'Tiago A');
      expect(updated.createdAt, profile.createdAt);
      expect(updated.plateInventory, profile.plateInventory);
      expect(updated.activeProgramId, 'program-1');
      expect(updated.activeGymId, 'gym-1');
    });

    test('replaces every field it is given', () {
      final later = now.add(const Duration(days: 1));
      final updated = profile.copyWith(
        displayName: 'Someone',
        units: UnitSystem.lb,
        barWeight: 15,
        plateInventory: const [20, 10],
        dumbbellIncrement: 2.5,
        updatedAt: later,
      );

      expect(updated.displayName, 'Someone');
      expect(updated.units, UnitSystem.lb);
      expect(updated.barWeight, 15);
      expect(updated.plateInventory, [20, 10]);
      expect(updated.dumbbellIncrement, 2.5);
      expect(updated.updatedAt, later);
    });

    test('clears an optional field when passed null explicitly', () {
      // The distinction a plain nullable parameter cannot express. Archiving a
      // program has to be able to unset activeProgramId, and silently ignoring
      // the null would leave the profile pointing at an archived program.
      final updated = profile.copyWith(activeProgramId: null);

      expect(updated.activeProgramId, isNull);
      expect(updated.activeGymId, 'gym-1', reason: 'omitted, so unchanged');
    });

    test('changing nothing produces an equal profile', () {
      expect(profile.copyWith(), profile);
    });
  });

  group('UserProfile favourites', () {
    // F2 needs favourites and §4 defined nowhere for them to live. They sit on
    // the profile document, which is already streamed, so they cost no extra
    // read (M2 amendment).
    final profile = UserProfile(displayName: 'Tiago', createdAt: now, updatedAt: now);

    test('start empty', () {
      expect(profile.favouriteExerciseIds, isEmpty);
      expect(profile.isFavourite('0043'), isFalse);
    });

    test('toggling adds and then removes', () {
      final starred = profile.toggleFavourite('0043');

      expect(starred.isFavourite('0043'), isTrue);
      expect(starred.toggleFavourite('0043').favouriteExerciseIds, isEmpty);
    });

    test('keeps the order they were starred in', () {
      final starred = profile.toggleFavourite('0043').toggleFavourite('0025');

      expect(starred.favouriteExerciseIds, ['0043', '0025']);
    });

    test('removing one leaves the rest where they were', () {
      final starred = profile
          .toggleFavourite('0043')
          .toggleFavourite('0025')
          .toggleFavourite('0032');

      expect(starred.toggleFavourite('0025').favouriteExerciseIds, ['0043', '0032']);
    });

    test('never mutates the profile it was called on', () {
      profile.toggleFavourite('0043');

      expect(profile.favouriteExerciseIds, isEmpty);
    });

    test('counts towards equality', () {
      expect(profile.toggleFavourite('0043'), isNot(profile));
    });
  });

  group('UnitSystem', () {
    test('wire values are the ones §4 stores', () {
      expect(UnitSystem.kg.wireValue, 'kg');
      expect(UnitSystem.lb.wireValue, 'lb');
    });

    test('reads back what it wrote', () {
      for (final units in UnitSystem.values) {
        expect(UnitSystem.fromWire(units.wireValue), units);
      }
    });

    test('falls back to kilograms for anything unrecognised', () {
      expect(UnitSystem.fromWire(null), UnitSystem.kg);
      expect(UnitSystem.fromWire('stones'), UnitSystem.kg);
      expect(UnitSystem.fromWire(7), UnitSystem.kg);
    });
  });
}
