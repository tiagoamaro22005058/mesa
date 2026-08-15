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
