// F3: "Create a program; set name, goal, days per week."
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/domain/models/auth_user.dart';
import 'package:mesa/domain/models/program.dart';
import 'package:mesa/domain/models/user_profile.dart';
import 'package:mesa/domain/models/week_role.dart';
import 'package:mesa/features/programs/presentation/program_form_screen.dart';

import '../../support/fakes.dart';
import '../../support/programs.dart';
import '../../support/pump_app.dart';

void main() {
  const user = AuthUser(uid: 'uid-a', email: 'a@example.com', displayName: 'Tiago');
  final now = DateTime.utc(2026, 8, 16);

  late FakeAuthRepository auth;
  late FakeUserProfileRepository profiles;
  late FakeProgramRepository programs;

  setUp(() {
    auth = FakeAuthRepository(initialUser: user);
    profiles = FakeUserProfileRepository();
    profiles.profiles['uid-a'] = UserProfile(
      displayName: 'Tiago',
      createdAt: now,
      updatedAt: now,
    );
    programs = FakeProgramRepository(profiles: profiles);
  });

  tearDown(() async {
    await auth.dispose();
    await profiles.dispose();
    await programs.dispose();
  });

  Future<void> pump(WidgetTester tester, {String? programId}) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpRoutedScreen(
      tester,
      ProgramFormScreen(programId: programId),
      auth: auth,
      profiles: profiles,
      programs: programs,
    );
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
  }

  Program saved() => programs.programs['uid-a']!.single;

  testWidgets('creates a program from the form', (tester) async {
    await pump(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'PPL');
    await tester.enterText(find.widgetWithText(TextFormField, 'Goal'), 'hypertrophy');
    await save(tester);

    expect(saved().name, 'PPL');
    expect(saved().goal, 'hypertrophy');
    expect(saved().status, ProgramStatus.draft);
  });

  testWidgets('a new program starts with §4\'s mesocycle', (tester) async {
    // Four fiddly forms between a new program and a usable one would work
    // against F3's five-minute criterion, so the defaults are seeded.
    await pump(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'PPL');
    await save(tester);

    expect(saved().weekRoles, WeekRole.defaults);
    expect(saved().weekRoles.map((role) => role.role), [
      WeekRoleKind.base,
      WeekRoleKind.intensification,
      WeekRoleKind.peak,
      WeekRoleKind.deload,
    ]);
  });

  testWidgets('refuses a program with no name', (tester) async {
    await pump(tester);

    await save(tester);

    expect(find.text('Enter your name'), findsOneWidget);
    expect(programs.programs['uid-a'], anyOf(isNull, isEmpty));
  });

  testWidgets('sessions per week defaults to three and must be whole', (tester) async {
    await pump(tester);

    expect(find.widgetWithText(TextFormField, 'Sessions per week'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'PPL');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sessions per week'),
      '3,5',
    );
    await save(tester);

    // A comma is a legal decimal separator (§9.1), which is exactly why a count
    // field has to reject the fraction rather than truncate it.
    expect(find.text('Enter a whole number'), findsOneWidget);
  });

  testWidgets('sessions per week is independent of the number of days', (tester) async {
    // A Push/Pull/Legs split run twice over is three days and six sessions.
    await pump(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'PPL');
    await tester.enterText(find.widgetWithText(TextFormField, 'Sessions per week'), '6');
    await save(tester);

    expect(saved().daysPerWeek, 6);
  });

  group('editing', () {
    setUp(() {
      programs.programs['uid-a'] = [
        program('program-1', 'PPL', goal: 'hypertrophy', daysPerWeek: 6),
      ];
    });

    testWidgets('loads the program into the form', (tester) async {
      await pump(tester, programId: 'program-1');

      expect(find.text('PPL'), findsOneWidget);
      expect(find.text('hypertrophy'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('keeps the id rather than creating a second program', (tester) async {
      await pump(tester, programId: 'program-1');

      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'PPL v2');
      await save(tester);

      expect(programs.programs['uid-a'], hasLength(1));
      expect(saved().id, 'program-1');
      expect(saved().name, 'PPL v2');
    });

    testWidgets('emptying the goal clears it rather than leaving the old one', (tester) async {
      // The copyWith sentinel is what makes this expressible at all: a plain
      // nullable parameter would read the null as "leave it alone".
      await pump(tester, programId: 'program-1');

      await tester.enterText(find.widgetWithText(TextFormField, 'Goal'), '');
      await save(tester);

      expect(saved().goal, isNull);
    });

    testWidgets('editing does not disturb the status or the counters', (tester) async {
      programs.programs['uid-a'] = [
        program(
          'program-1',
          'PPL',
          status: ProgramStatus.active,
          currentMesocycle: 3,
          currentWeekIndex: 2,
        ),
      ];

      await pump(tester, programId: 'program-1');

      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'PPL v2');
      await save(tester);

      expect(saved().status, ProgramStatus.active);
      expect(saved().currentMesocycle, 3);
      expect(saved().currentWeekIndex, 2);
    });

    testWidgets('reports a program that no longer exists', (tester) async {
      await pump(tester, programId: 'gone');

      expect(find.text('That program no longer exists.'), findsOneWidget);
    });
  });
}
