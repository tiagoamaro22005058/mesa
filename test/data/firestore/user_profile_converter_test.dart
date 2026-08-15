import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/data/firestore/converters/user_profile_converter.dart';
import 'package:mesa/domain/models/unit_system.dart';
import 'package:mesa/domain/models/user_profile.dart';

void main() {
  final created = DateTime.utc(2026, 1, 2, 3, 4, 5);
  final updated = DateTime.utc(2026, 8, 15, 10, 30);

  group('UserProfileConverter', () {
    test('round-trips a full profile', () {
      final profile = UserProfile(
        displayName: 'Tiago',
        units: UnitSystem.lb,
        barWeight: 15,
        plateInventory: const [20, 10, 5],
        dumbbellIncrement: 2.5,
        activeProgramId: 'program-1',
        activeGymId: 'gym-1',
        createdAt: created,
        updatedAt: updated,
      );

      final restored = UserProfileConverter.fromMap(
        UserProfileConverter.toMap(profile),
      );

      expect(restored, profile);
    });

    test('writes the enum wire value, not the Dart name', () {
      final map = UserProfileConverter.toMap(
        UserProfile(
          displayName: 'Tiago',
          units: UnitSystem.lb,
          createdAt: created,
          updatedAt: updated,
        ),
      );

      expect(map['units'], 'lb');
    });

    test('writes timestamps rather than DateTimes', () {
      final map = UserProfileConverter.toMap(
        UserProfile(displayName: 'Tiago', createdAt: created, updatedAt: updated),
      );

      expect(map['createdAt'], isA<Timestamp>());
      expect((map['createdAt'] as Timestamp).toDate().toUtc(), created);
    });

    test('widens whole numbers, which Firestore hands back as int', () {
      // A barWeight of 20.0 comes back from Firestore as the int 20; a naive
      // cast to double throws on exactly the default profile.
      final restored = UserProfileConverter.fromMap({
        'displayName': 'Tiago',
        'barWeight': 20,
        'dumbbellIncrement': 2,
        'plateInventory': [25, 20, 15, 10, 5, 2.5, 1.25],
        'createdAt': Timestamp.fromDate(created),
        'updatedAt': Timestamp.fromDate(updated),
      });

      expect(restored.barWeight, 20.0);
      expect(restored.dumbbellIncrement, 2.0);
      expect(restored.plateInventory, [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25]);
    });

    test('substitutes §4 defaults for absent fields', () {
      final restored = UserProfileConverter.fromMap({'displayName': 'Tiago'});

      expect(restored.units, UnitSystem.kg);
      expect(restored.barWeight, UserProfile.defaultBarWeight);
      expect(restored.plateInventory, UserProfile.defaultPlateInventory);
      expect(restored.dumbbellIncrement, UserProfile.defaultDumbbellIncrement);
    });

    test('survives a document written with the wrong types', () {
      // The rules validate nothing (§4.3), so a malformed document is
      // reachable. Refusing to parse it would lock the user out of their own
      // profile screen, which is the only place they could fix it.
      final restored = UserProfileConverter.fromMap({
        'displayName': 42,
        'units': 'stones',
        'barWeight': 'heavy',
        'plateInventory': ['25', 20],
        'dumbbellIncrement': null,
      });

      expect(restored.displayName, '');
      expect(restored.units, UnitSystem.kg);
      expect(restored.barWeight, UserProfile.defaultBarWeight);
      expect(restored.plateInventory, UserProfile.defaultPlateInventory);
      expect(restored.dumbbellIncrement, UserProfile.defaultDumbbellIncrement);
    });
  });
}
