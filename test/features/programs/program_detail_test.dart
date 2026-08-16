// F3: "Duplicate a day; duplicate a program; archive a program" and
// "Exactly one program may be `active` at a time".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/domain/models/auth_user.dart';
import 'package:mesa/domain/models/program.dart';
import 'package:mesa/domain/models/user_profile.dart';
import 'package:mesa/features/programs/presentation/program_detail_screen.dart';

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
    programs.programs['uid-a'] = [program('program-1', 'PPL')];
  });

  tearDown(() async {
    await auth.dispose();
    await profiles.dispose();
    await programs.dispose();
  });

  Future<void> pump(WidgetTester tester, {String programId = 'program-1'}) async {
    // Tall enough that the day list and the Add day button are both on screen.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpRoutedScreen(
      tester,
      ProgramDetailScreen(programId: programId),
      auth: auth,
      profiles: profiles,
      programs: programs,
    );
  }

  Program stored(String id) =>
      programs.programs['uid-a']!.firstWhere((p) => p.id == id);

  testWidgets('reports a program that no longer exists', (tester) async {
    await pump(tester, programId: 'gone');

    expect(find.text('That program no longer exists.'), findsOneWidget);
  });

  group('activation', () {
    testWidgets('makes the program active and points the profile at it', (tester) async {
      // §4 stores the active program in two places. The repository writes both
      // in one batch precisely so a test like this cannot pass with only one
      // of them updated.
      await pump(tester);

      await tester.tap(find.text('Make active'));
      await tester.pumpAndSettle();

      expect(stored('program-1').status, ProgramStatus.active);
      expect(profiles.profiles['uid-a']!.activeProgramId, 'program-1');
    });

    testWidgets('demotes the program it displaces, after confirming', (tester) async {
      programs.programs['uid-a'] = [
        program('program-1', 'PPL'),
        program('program-2', 'Upper/Lower', status: ProgramStatus.active),
      ];

      await pump(tester);

      await tester.tap(find.text('Make active'));
      await tester.pumpAndSettle();

      // Displacing something the user set up is worth asking about first.
      expect(find.textContaining('Upper/Lower will go back to draft'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Make active'));
      await tester.pumpAndSettle();

      expect(stored('program-1').status, ProgramStatus.active);
      expect(stored('program-2').status, ProgramStatus.draft);
      expect(profiles.profiles['uid-a']!.activeProgramId, 'program-1');
    });

    testWidgets('cancelling leaves both programs where they were', (tester) async {
      programs.programs['uid-a'] = [
        program('program-1', 'PPL'),
        program('program-2', 'Upper/Lower', status: ProgramStatus.active),
      ];

      await pump(tester);

      await tester.tap(find.text('Make active'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(stored('program-1').status, ProgramStatus.draft);
      expect(stored('program-2').status, ProgramStatus.active);
    });

    testWidgets('offers nothing to activate on the program already active', (tester) async {
      programs.programs['uid-a'] = [
        program('program-1', 'PPL', status: ProgramStatus.active),
      ];

      await pump(tester);

      expect(find.text('Make active'), findsNothing);
    });
  });

  group('archiving', () {
    testWidgets('asks first, then archives', (tester) async {
      await pump(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive').last);
      await tester.pumpAndSettle();

      // NFR5: no destructive action without confirmation.
      expect(find.text('Archive this program?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Archive'));
      await tester.pumpAndSettle();

      expect(stored('program-1').status, ProgramStatus.archived);
    });

    testWidgets('cancelling leaves the program alone', (tester) async {
      await pump(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(stored('program-1').status, ProgramStatus.draft);
    });

    testWidgets('clears the profile pointer when archiving the active program', (tester) async {
      // Otherwise M4 would start a session from a program the user retired.
      programs.programs['uid-a'] = [
        program('program-1', 'PPL', status: ProgramStatus.active),
      ];
      profiles.profiles['uid-a'] = profiles.profiles['uid-a']!.copyWith(
        activeProgramId: 'program-1',
      );

      await pump(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Archive'));
      await tester.pumpAndSettle();

      expect(profiles.profiles['uid-a']!.activeProgramId, isNull);
    });
  });

  group('duplication', () {
    testWidgets('copies the program and its days as a fresh draft', (tester) async {
      programs.days['uid-a/program-1'] = [
        day('day-1', 'Push', blocks: [block('block-1', '0025')]),
        day('day-2', 'Pull', order: 1),
      ];

      await pump(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duplicate').last);
      await tester.pumpAndSettle();

      final copy = programs.programs['uid-a']!.firstWhere((p) => p.id != 'program-1');
      expect(copy.name, 'PPL (copy)');
      expect(copy.status, ProgramStatus.draft);
      expect(programs.days['uid-a/${copy.id}'], hasLength(2));
    });

    testWidgets('gives the copy its own day and block ids', (tester) async {
      // Sharing a blockId with the original would leave M4 unable to say which
      // program a logged set belonged to.
      programs.days['uid-a/program-1'] = [
        day('day-1', 'Push', blocks: [block('block-1', '0025')]),
      ];

      await pump(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duplicate').last);
      await tester.pumpAndSettle();

      final copyId = programs.programs['uid-a']!
          .firstWhere((p) => p.id != 'program-1')
          .id;
      final copied = programs.days['uid-a/$copyId']!.single;

      expect(copied.id, isNot('day-1'));
      expect(copied.blocks.single.blockId, isNot('block-1'));
      expect(copied.blocks.single.exerciseId, '0025', reason: 'same exercise');
    });

    testWidgets('never makes the copy active', (tester) async {
      // Exactly one program may be active (F3), so a copy that took the slot
      // would silently displace the program being copied.
      programs.programs['uid-a'] = [
        program('program-1', 'PPL', status: ProgramStatus.active),
      ];

      await pump(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duplicate').last);
      await tester.pumpAndSettle();

      final copy = programs.programs['uid-a']!.firstWhere((p) => p.id != 'program-1');
      expect(copy.status, ProgramStatus.draft);
      expect(stored('program-1').status, ProgramStatus.active);
    });
  });

  group('days', () {
    testWidgets('appends a day', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Add day'));
      await tester.pumpAndSettle();

      expect(programs.days['uid-a/program-1'], hasLength(1));
      expect(programs.days['uid-a/program-1']!.single.name, 'New day');
    });

    testWidgets('lists the days in order, with their block counts', (tester) async {
      programs.days['uid-a/program-1'] = [
        day('day-2', 'Pull', order: 1),
        day('day-1', 'Push', blocks: [block('block-1', '0025')]),
      ];

      await pump(tester);

      expect(
        tester.getTopLeft(find.text('Push')).dy,
        lessThan(tester.getTopLeft(find.text('Pull')).dy),
      );
      expect(find.text('1 exercise'), findsOneWidget);
      expect(find.text('No exercises'), findsOneWidget);
    });

    testWidgets('a drag renumbers the days it moved', (tester) async {
      programs.days['uid-a/program-1'] = [
        day('day-1', 'Push'),
        day('day-2', 'Pull', order: 1),
        day('day-3', 'Legs', order: 2),
      ];

      await pump(tester);

      // Drag "Push" past "Pull". `onReorderItem` reports the destination index
      // already adjusted, so a stale off-by-one correction would land it one
      // place short — which is what this asserts against.
      final handle = find.byIcon(Icons.drag_handle).first;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump(const Duration(milliseconds: 200));
      // Moved in steps: the first nudge is what the drag recogniser needs to
      // accept the gesture, and the list only reorders once it has.
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 100));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final ordered = [...programs.days['uid-a/program-1']!]
        ..sort((a, b) => a.order.compareTo(b.order));

      expect(ordered.map((d) => d.name), ['Pull', 'Push', 'Legs']);
      expect(ordered.map((d) => d.order), [0, 1, 2]);
    });
  });
}
