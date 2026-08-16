// §3/§4: Program and WeekRole.
//
// The `copyWith` completeness table is §2's freezed replacement — see
// `test/support/copy_with.dart` for what it does and does not prove.
import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/domain/models/program.dart';
import 'package:mesa/domain/models/week_role.dart';

import '../../support/copy_with.dart';

void main() {
  final now = DateTime.utc(2026, 8, 16);

  Program build() => Program(
    id: 'program-1',
    name: 'PPL',
    goal: 'hypertrophy',
    createdAt: now,
    updatedAt: now,
  );

  group('Program defaults', () {
    test('match §4', () {
      final program = build();

      expect(program.status, ProgramStatus.draft);
      expect(program.currentMesocycle, 1);
      expect(program.currentWeekIndex, 0);
      expect(program.daysPerWeek, 3);
      expect(program.weekRoles, WeekRole.defaults);
    });

    test('a new program is a draft, not active', () {
      // Exactly one program may be active (F3), so creating one cannot make it
      // so on its own — activation is a deliberate, batched act.
      expect(build().isActive, isFalse);
    });
  });

  group('Program.copyWith', () {
    test('covers every field', () {
      final program = build();

      expectCopyWithCoversEveryField(program, {
        'id': program.copyWith(id: 'program-2'),
        'name': program.copyWith(name: 'Upper/Lower'),
        'goal': program.copyWith(goal: 'strength'),
        'status': program.copyWith(status: ProgramStatus.active),
        'weekRoles': program.copyWith(weekRoles: const []),
        'currentMesocycle': program.copyWith(currentMesocycle: 2),
        'currentWeekIndex': program.copyWith(currentWeekIndex: 3),
        'daysPerWeek': program.copyWith(daysPerWeek: 6),
        'createdAt': program.copyWith(createdAt: now.add(const Duration(days: 1))),
        'updatedAt': program.copyWith(updatedAt: now.add(const Duration(days: 1))),
      });
    });

    test('leaves untouched fields alone', () {
      final updated = build().copyWith(name: 'PPL v2');

      expect(updated.name, 'PPL v2');
      expect(updated.goal, 'hypertrophy');
      expect(updated.createdAt, now);
      expect(updated.weekRoles, WeekRole.defaults);
    });

    test('clears the goal when passed null explicitly', () {
      // The distinction a plain nullable parameter cannot express: a user who
      // empties the goal field means to empty it, not to leave it as it was.
      final updated = build().copyWith(goal: null);

      expect(updated.goal, isNull);
      expect(updated.name, 'PPL', reason: 'omitted, so unchanged');
    });

    test('changing nothing produces an equal program', () {
      expect(build().copyWith(), build());
    });
  });

  group('Program equality', () {
    test('compares week roles by value, not by identity', () {
      // A program read back from Firestore holds a different list object with
      // the same roles in it; comparing by identity would call every reload a
      // change.
      final roles = [
        const WeekRole(role: WeekRoleKind.base, rpeTarget: 7, volumeMultiplier: 1),
      ];
      final other = [
        const WeekRole(role: WeekRoleKind.base, rpeTarget: 7, volumeMultiplier: 1),
      ];

      expect(build().copyWith(weekRoles: roles), build().copyWith(weekRoles: other));
      expect(
        build().copyWith(weekRoles: roles).hashCode,
        build().copyWith(weekRoles: other).hashCode,
      );
    });

    test('notices a changed week role', () {
      final harder = [...WeekRole.defaults]
        ..[0] = const WeekRole(
          role: WeekRoleKind.base,
          rpeTarget: 8,
          volumeMultiplier: 1,
        );

      expect(build().copyWith(weekRoles: harder), isNot(build()));
    });
  });

  group('ProgramStatus', () {
    test('wire values are the ones §4 stores', () {
      expect(ProgramStatus.draft.wireValue, 'draft');
      expect(ProgramStatus.active.wireValue, 'active');
      expect(ProgramStatus.archived.wireValue, 'archived');
    });

    test('reads back what it wrote', () {
      for (final status in ProgramStatus.values) {
        expect(ProgramStatus.tryFromWire(status.wireValue), status);
      }
    });

    test('returns null for anything unrecognised, leaving the policy to the caller', () {
      expect(ProgramStatus.tryFromWire('paused'), isNull);
      expect(ProgramStatus.tryFromWire(null), isNull);
      expect(ProgramStatus.tryFromWire(3), isNull);
    });
  });

  group('WeekRole', () {
    test('defaults are §4\'s mesocycle, in §4\'s order', () {
      // §3 and §12 wrote a different order (Base / Deload / Intensification /
      // Peak); §4's is the one that ships, confirmed by the owner in M3.
      expect(
        WeekRole.defaults.map((role) => role.role),
        [
          WeekRoleKind.base,
          WeekRoleKind.intensification,
          WeekRoleKind.peak,
          WeekRoleKind.deload,
        ],
      );
      expect(WeekRole.defaults.map((role) => role.rpeTarget), [7, 8.5, 9.5, 5.5]);
      expect(WeekRole.defaults.map((role) => role.volumeMultiplier), [1, 1, 0.9, 0.5]);
    });

    test('copyWith covers every field', () {
      const role = WeekRole(
        role: WeekRoleKind.base,
        rpeTarget: 7,
        volumeMultiplier: 1,
      );

      expectCopyWithCoversEveryField(role, {
        'role': role.copyWith(role: WeekRoleKind.peak),
        'rpeTarget': role.copyWith(rpeTarget: 9.5),
        'volumeMultiplier': role.copyWith(volumeMultiplier: 0.5),
      });
    });

    test('a mesocycle may repeat a role', () {
      // A2 makes the roles user-configurable, and two base weeks is an ordinary
      // mesocycle. A week's identity is its position in the list, not its name,
      // which is why these are list entries rather than data on the enum.
      final roles = [
        const WeekRole(role: WeekRoleKind.base, rpeTarget: 7, volumeMultiplier: 1),
        const WeekRole(role: WeekRoleKind.base, rpeTarget: 7.5, volumeMultiplier: 1),
      ];

      expect(build().copyWith(weekRoles: roles).weekRoles, hasLength(2));
      expect(roles.first, isNot(roles.last));
    });

    test('wire values are the ones §4 stores', () {
      expect(WeekRoleKind.base.wireValue, 'base');
      expect(WeekRoleKind.intensification.wireValue, 'intensification');
      expect(WeekRoleKind.peak.wireValue, 'peak');
      expect(WeekRoleKind.deload.wireValue, 'deload');
    });

    test('reads back what it wrote', () {
      for (final kind in WeekRoleKind.values) {
        expect(WeekRoleKind.tryFromWire(kind.wireValue), kind);
      }
    });
  });
}
