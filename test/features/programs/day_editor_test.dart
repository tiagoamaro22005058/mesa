// F3: "Add days, name and reorder them" and "Within a day: add exercise
// blocks, reorder by drag".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/domain/models/auth_user.dart';
import 'package:mesa/domain/models/day.dart';
import 'package:mesa/domain/models/user_profile.dart';
import 'package:mesa/features/programs/presentation/day_editor_screen.dart';

import '../../support/exercises.dart';
import '../../support/fakes.dart';
import '../../support/programs.dart';
import '../../support/pump_app.dart';

void main() {
  const user = AuthUser(uid: 'uid-a', email: 'a@example.com', displayName: 'Tiago');
  final now = DateTime.utc(2026, 8, 16);

  late FakeAuthRepository auth;
  late FakeUserProfileRepository profiles;
  late FakeProgramRepository programs;
  late FakeExerciseCatalog catalog;

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
    catalog = FakeExerciseCatalog(
      exercises: [
        exercise('0025', 'barbell bench press'),
        exercise('0334', 'dumbbell lateral raise'),
        exercise('0201', 'cable pushdown'),
      ],
    );
  });

  tearDown(() async {
    await auth.dispose();
    await profiles.dispose();
    await programs.dispose();
  });

  Future<void> pump(WidgetTester tester, {String dayId = 'day-1'}) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpRoutedScreen(
      tester,
      DayEditorScreen(programId: 'program-1', dayId: dayId),
      auth: auth,
      profiles: profiles,
      programs: programs,
      catalog: catalog,
    );
  }

  Day stored() => programs.days['uid-a/program-1']!.firstWhere((d) => d.id == 'day-1');

  testWidgets('reports a day that no longer exists', (tester) async {
    await pump(tester, dayId: 'gone');

    expect(find.text('That day no longer exists.'), findsOneWidget);
  });

  testWidgets('invites the user to add exercises when the day is empty', (tester) async {
    programs.days['uid-a/program-1'] = [day('day-1', 'Push')];

    await pump(tester);

    expect(find.text('No exercises yet'), findsOneWidget);
    expect(find.text('Add exercise'), findsOneWidget);
  });

  testWidgets('lists each block with what it prescribes', (tester) async {
    programs.days['uid-a/program-1'] = [
      day('day-1', 'Push', blocks: [block('block-1', '0025')]),
    ];

    await pump(tester);

    expect(find.text('Barbell Bench Press'), findsOneWidget);
    // §4's example scheme, which is what a new block starts from.
    expect(find.textContaining('4 × 6-8 @ RPE 8'), findsOneWidget);
    expect(find.textContaining('150s rest'), findsOneWidget);
  });

  testWidgets('still renders a block whose exercise is gone', (tester) async {
    // A deleted custom exercise must not blank out the day around it.
    programs.days['uid-a/program-1'] = [
      day('day-1', 'Push', blocks: [block('block-1', 'custom-gone', isCustom: true)]),
    ];

    await pump(tester);

    expect(find.text('Exercise no longer available'), findsOneWidget);
  });

  testWidgets('counts a block\'s alternatives', (tester) async {
    programs.days['uid-a/program-1'] = [
      day(
        'day-1',
        'Push',
        blocks: [
          block('block-1', '0025', alternativeExerciseIds: ['0334', '0201']),
        ],
      ),
    ];

    await pump(tester);

    expect(find.textContaining('2 alternatives'), findsOneWidget);
  });

  testWidgets('a drag reorders the blocks', (tester) async {
    programs.days['uid-a/program-1'] = [
      day(
        'day-1',
        'Push',
        blocks: [
          block('block-1', '0025'),
          block('block-2', '0334'),
          block('block-3', '0201'),
        ],
      ),
    ];

    await pump(tester);

    // Position in `Day.blocks` *is* the order — §4's `order` field is written
    // from the index and never read back as the source of truth.
    final handle = find.byIcon(Icons.drag_handle).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 100));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(stored().blocks.map((b) => b.blockId), [
      'block-2',
      'block-1',
      'block-3',
    ]);
  });

  group('renaming', () {
    testWidgets('renames the day', (tester) async {
      // A day called "New day" has to be cheap to fix — F3 allows five minutes
      // for the whole program.
      programs.days['uid-a/program-1'] = [day('day-1', 'New day')];

      await pump(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename day').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Push');
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      expect(stored().name, 'Push');
    });

    testWidgets('cancelling leaves the name alone', (tester) async {
      programs.days['uid-a/program-1'] = [day('day-1', 'Push')];

      await pump(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename day').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Pull');
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(stored().name, 'Push');
    });
  });

  group('deleting', () {
    testWidgets('asks first, then deletes', (tester) async {
      programs.days['uid-a/program-1'] = [day('day-1', 'Push')];

      await pump(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      // NFR5: no destructive action without confirmation.
      expect(find.text('Delete this day?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(programs.days['uid-a/program-1'], isEmpty);
    });

    testWidgets('cancelling keeps the day', (tester) async {
      programs.days['uid-a/program-1'] = [day('day-1', 'Push')];

      await pump(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(programs.days['uid-a/program-1'], hasLength(1));
    });
  });

  testWidgets('duplicates the day with fresh block ids', (tester) async {
    programs.days['uid-a/program-1'] = [
      day('day-1', 'Push', blocks: [block('block-1', '0025')]),
    ];

    await pump(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate').last);
    await tester.pumpAndSettle();

    final copy = programs.days['uid-a/program-1']!.firstWhere((d) => d.id != 'day-1');
    expect(copy.name, 'Push (copy)');
    expect(copy.blocks.single.blockId, isNot('block-1'));
    expect(copy.blocks.single.exerciseId, '0025');
  });
}
