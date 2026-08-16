// §4: the `users/{uid}/programs/{programId}` document.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/data/firestore/converters/program_converter.dart';
import 'package:mesa/domain/models/program.dart';
import 'package:mesa/domain/models/week_role.dart';

void main() {
  final now = DateTime.utc(2026, 8, 16, 10, 30);

  group('ProgramConverter', () {
    test('round-trips a program', () {
      final original = Program(
        id: 'program-1',
        name: 'PPL',
        goal: 'hypertrophy',
        status: ProgramStatus.active,
        currentMesocycle: 2,
        currentWeekIndex: 3,
        daysPerWeek: 6,
        createdAt: now,
        updatedAt: now,
      );

      final restored = ProgramConverter.fromMap(
        'program-1',
        ProgramConverter.toMap(original),
      );

      expect(restored, original);
    });

    test('round-trips a program with no goal', () {
      final original = Program(
        id: 'program-1',
        name: 'PPL',
        createdAt: now,
        updatedAt: now,
      );

      final restored = ProgramConverter.fromMap(
        'program-1',
        ProgramConverter.toMap(original),
      );

      expect(restored.goal, isNull);
      expect(restored, original);
    });

    test('round-trips a mesocycle that repeats a role', () {
      // A2 makes the roles user-configurable, and two base weeks is ordinary.
      // The wire format is a list, so nothing keys on the role name.
      final roles = [
        const WeekRole(role: WeekRoleKind.base, rpeTarget: 7, volumeMultiplier: 1),
        const WeekRole(role: WeekRoleKind.base, rpeTarget: 7.5, volumeMultiplier: 1),
        const WeekRole(role: WeekRoleKind.deload, rpeTarget: 5.5, volumeMultiplier: 0.5),
      ];
      final original = Program(
        id: 'program-1',
        name: 'PPL',
        weekRoles: roles,
        createdAt: now,
        updatedAt: now,
      );

      final restored = ProgramConverter.fromMap(
        'program-1',
        ProgramConverter.toMap(original),
      );

      expect(restored.weekRoles, roles);
    });

    test('writes timestamps as client clocks, not server sentinels', () {
      // NFR1: a FieldValue.serverTimestamp() reads back null from the offline
      // cache until it syncs, so a user with no signal would see no dates.
      final map = ProgramConverter.toMap(
        Program(id: 'program-1', name: 'PPL', createdAt: now, updatedAt: now),
      );

      expect(map['createdAt'], isA<Timestamp>());
      expect((map['createdAt'] as Timestamp).toDate().toUtc(), now);
    });

    test('falls back to a visible default rather than throwing', () {
      // Deliberately tolerant. The rules authenticate but do not validate
      // (§4.3), and a program that refuses to parse would take the builder down.
      final restored = ProgramConverter.fromMap('program-1', {
        'name': 'Mystery',
        'status': 'paused',
        'currentMesocycle': 'soon',
        'daysPerWeek': <String>[],
      });

      expect(restored.name, 'Mystery');
      expect(restored.currentMesocycle, 1);
      expect(restored.daysPerWeek, Program.defaultDaysPerWeek);
    });

    test('an unrecognised status reads as a draft, never as active', () {
      // Guessing "active" would give the user two active programs, which is the
      // one thing F3 says cannot happen.
      final restored = ProgramConverter.fromMap('program-1', {'status': 'running'});

      expect(restored.status, ProgramStatus.draft);
      expect(restored.isActive, isFalse);
    });

    test('drops a week role it cannot name rather than renaming it', () {
      // The rest of this converter substitutes defaults. Not here: a week
      // silently renamed to `base` keeps its slot and prescribes the wrong RPE
      // for it, which nothing would ever show the user. A missing week is at
      // least visible in the list.
      final restored = ProgramConverter.fromMap('program-1', {
        'weekRoles': [
          {'role': 'base', 'rpeTarget': 7, 'volumeMultiplier': 1},
          {'role': 'hypertrophy', 'rpeTarget': 8, 'volumeMultiplier': 1},
          {'role': 'deload', 'rpeTarget': 5.5, 'volumeMultiplier': 0.5},
        ],
      });

      expect(restored.weekRoles.map((role) => role.role), [
        WeekRoleKind.base,
        WeekRoleKind.deload,
      ]);
    });

    test('an absent or empty week-role list falls back to §4\'s mesocycle', () {
      // A program with no weeks at all cannot prescribe anything, so this is
      // the one case where substituting is better than dropping.
      expect(ProgramConverter.fromMap('p', const {}).weekRoles, WeekRole.defaults);
      expect(
        ProgramConverter.fromMap('p', {'weekRoles': <Object>[]}).weekRoles,
        WeekRole.defaults,
      );
    });

    test('survives a document with almost nothing in it', () {
      final restored = ProgramConverter.fromMap('program-1', const {});

      expect(restored.id, 'program-1');
      expect(restored.name, '');
      expect(restored.goal, isNull);
      expect(restored.status, ProgramStatus.draft);
      expect(restored.currentMesocycle, 1);
      expect(restored.currentWeekIndex, 0);
      expect(restored.createdAt, DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
    });

    test('widens a whole number Firestore hands back as an int', () {
      // Firestore returns `int` for a double written as 1.0, so a plain cast
      // to double would throw on a volume multiplier of exactly 1.
      final restored = ProgramConverter.fromMap('program-1', {
        'weekRoles': [
          {'role': 'base', 'rpeTarget': 7, 'volumeMultiplier': 1},
        ],
      });

      expect(restored.weekRoles.single.rpeTarget, 7.0);
      expect(restored.weekRoles.single.volumeMultiplier, 1.0);
    });
  });
}
