// F3: "Within a day: add exercise blocks, ... set the scheme (sets, rep range,
// target RPE, rest), add free-text notes" and "Per block, pick ordered
// alternatives".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/domain/models/auth_user.dart';
import 'package:mesa/domain/models/block.dart';
import 'package:mesa/domain/models/set_scheme.dart';
import 'package:mesa/domain/models/user_profile.dart';
import 'package:mesa/features/programs/presentation/block_form_screen.dart';

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
  late FakeCustomExerciseRepository customExercises;

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
    programs.days['uid-a/program-1'] = [day('day-1', 'Push')];
    catalog = FakeExerciseCatalog(
      exercises: [
        exercise('0025', 'barbell bench press'),
        exercise('0289', 'dumbbell bench press'),
        exercise('0334', 'dumbbell lateral raise'),
      ],
    );
    customExercises = FakeCustomExerciseRepository();
  });

  tearDown(() async {
    await auth.dispose();
    await profiles.dispose();
    await programs.dispose();
    await customExercises.dispose();
  });

  Future<void> pump(WidgetTester tester, {String? blockId}) async {
    // Tall enough that the whole form, alternatives included, is on screen.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpRoutedScreen(
      tester,
      BlockFormScreen(programId: 'program-1', dayId: 'day-1', blockId: blockId),
      auth: auth,
      profiles: profiles,
      programs: programs,
      catalog: catalog,
      customExercises: customExercises,
    );
  }

  Future<void> pick(WidgetTester tester, String label, String name) async {
    await tester.tap(find.widgetWithText(OutlinedButton, label));
    await tester.pumpAndSettle();
    // `.last` is the row inside the modal: the sheet is pushed on top, so its
    // widgets come later in the tree than an alternative of the same name
    // already listed on the form behind it.
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
  }

  Block? saved() =>
      programs.days['uid-a/program-1']!.single.blocks.firstOrNull;

  testWidgets('starts from §4\'s example scheme', (tester) async {
    await pump(tester);

    expect(find.widgetWithText(TextFormField, 'Sets'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('8'), findsWidgets);
  });

  testWidgets('adds a block from the picker', (tester) async {
    await pump(tester);

    await pick(tester, 'Choose an exercise', 'Barbell Bench Press');
    await save(tester);

    expect(saved()!.exerciseId, '0025');
    expect(saved()!.isCustom, isFalse);
  });

  testWidgets('marks a block whose exercise the user created', (tester) async {
    // Derived from the picked exercise, never typed — §4 stores it so a day
    // document says where to resolve the id without loading the catalogue.
    customExercises.exercises['uid-a'] = [
      customExercise('custom-1', 'my gym chest press'),
    ];

    await pump(tester);

    await pick(tester, 'Choose an exercise', 'My Gym Chest Press');
    await save(tester);

    expect(saved()!.exerciseId, 'custom-1');
    expect(saved()!.isCustom, isTrue);
  });

  testWidgets('refuses to save a block with no exercise', (tester) async {
    await pump(tester);

    await save(tester);

    expect(programs.days['uid-a/program-1']!.single.blocks, isEmpty);
    expect(find.text('Choose an exercise'), findsWidgets);
  });

  group('the set scheme', () {
    testWidgets('saves what was typed', (tester) async {
      await pump(tester);

      await pick(tester, 'Choose an exercise', 'Barbell Bench Press');
      await tester.enterText(find.widgetWithText(TextFormField, 'Sets'), '5');
      await tester.enterText(find.widgetWithText(TextFormField, 'Reps from'), '3');
      await tester.enterText(find.widgetWithText(TextFormField, 'to'), '5');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Rest (seconds)'),
        '180',
      );
      await save(tester);

      expect(saved()!.setScheme, const SetScheme(
        sets: 5,
        repMin: 3,
        repMax: 5,
        rpeTarget: 8,
        restSec: 180,
      ));
    });

    testWidgets('rejects an inverted rep range', (tester) async {
      await pump(tester);

      await pick(tester, 'Choose an exercise', 'Barbell Bench Press');
      await tester.enterText(find.widgetWithText(TextFormField, 'Reps from'), '10');
      await tester.enterText(find.widgetWithText(TextFormField, 'to'), '5');
      await save(tester);

      expect(
        find.text('The top of the range must not be below the bottom'),
        findsOneWidget,
      );
      expect(programs.days['uid-a/program-1']!.single.blocks, isEmpty);
    });

    testWidgets('accepts a fixed rep count', (tester) async {
      await pump(tester);

      await pick(tester, 'Choose an exercise', 'Barbell Bench Press');
      await tester.enterText(find.widgetWithText(TextFormField, 'Reps from'), '5');
      await tester.enterText(find.widgetWithText(TextFormField, 'to'), '5');
      await save(tester);

      expect(saved()!.setScheme.repMin, 5);
      expect(saved()!.setScheme.repMax, 5);
    });

    testWidgets('rejects a fractional number of sets', (tester) async {
      await pump(tester);

      await pick(tester, 'Choose an exercise', 'Barbell Bench Press');
      await tester.enterText(find.widgetWithText(TextFormField, 'Sets'), '3,5');
      await save(tester);

      // A comma is a legal decimal separator (§9.1), which is exactly why a
      // count field has to reject the fraction rather than truncate it.
      expect(find.text('Enter a whole number'), findsOneWidget);
    });

    testWidgets('allows no rest at all', (tester) async {
      // Zero is a real prescription — a superset has no rest between its parts.
      await pump(tester);

      await pick(tester, 'Choose an exercise', 'Barbell Bench Press');
      await tester.enterText(find.widgetWithText(TextFormField, 'Rest (seconds)'), '0');
      await save(tester);

      expect(saved()!.setScheme.restSec, 0);
    });

    testWidgets('picks the RPE target from the half-point scale', (tester) async {
      await pump(tester);

      await pick(tester, 'Choose an exercise', 'Barbell Bench Press');
      await tester.tap(find.byType(DropdownButtonFormField<double>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('9.5').last);
      await tester.pumpAndSettle();
      await save(tester);

      expect(saved()!.setScheme.rpeTarget, 9.5);
    });
  });

  group('alternatives', () {
    testWidgets('adds them in the order they were picked', (tester) async {
      // The list is the user's preference ranking (F3). §F7's computed ranking
      // arrives in M7 and never outranks this.
      await pump(tester);

      await pick(tester, 'Choose an exercise', 'Barbell Bench Press');
      await pick(tester, 'Add alternative', 'Dumbbell Bench Press');
      await pick(tester, 'Add alternative', 'Dumbbell Lateral Raise');
      await save(tester);

      expect(saved()!.alternativeExerciseIds, ['0289', '0334']);
    });

    testWidgets('refuses to rank the same exercise twice', (tester) async {
      await pump(tester);

      await pick(tester, 'Choose an exercise', 'Barbell Bench Press');
      await pick(tester, 'Add alternative', 'Dumbbell Bench Press');
      await pick(tester, 'Add alternative', 'Dumbbell Bench Press');
      await save(tester);

      expect(saved()!.alternativeExerciseIds, ['0289']);
    });

    testWidgets('removes one', (tester) async {
      await pump(tester);

      await pick(tester, 'Choose an exercise', 'Barbell Bench Press');
      await pick(tester, 'Add alternative', 'Dumbbell Bench Press');

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await save(tester);

      expect(saved()!.alternativeExerciseIds, isEmpty);
    });
  });

  group('editing', () {
    setUp(() {
      programs.days['uid-a/program-1'] = [
        day(
          'day-1',
          'Push',
          blocks: [
            block(
              'block-1',
              '0025',
              setScheme: const SetScheme(
                sets: 3,
                repMin: 8,
                repMax: 12,
                rpeTarget: 7,
                restSec: 90,
              ),
              alternativeExerciseIds: ['0289'],
              notes: 'pause on the chest',
            ),
          ],
        ),
      ];
    });

    testWidgets('loads the block into the form', (tester) async {
      await pump(tester, blockId: 'block-1');

      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(find.text('pause on the chest'), findsOneWidget);
      expect(find.text('Dumbbell Bench Press'), findsOneWidget);
    });

    testWidgets('keeps the block id rather than adding a second', (tester) async {
      await pump(tester, blockId: 'block-1');

      await tester.enterText(find.widgetWithText(TextFormField, 'Sets'), '4');
      await save(tester);

      expect(programs.days['uid-a/program-1']!.single.blocks, hasLength(1));
      expect(saved()!.blockId, 'block-1');
      expect(saved()!.setScheme.sets, 4);
    });

    testWidgets('emptying the notes clears them', (tester) async {
      await pump(tester, blockId: 'block-1');

      await tester.enterText(find.widgetWithText(TextFormField, 'Notes'), '');
      await save(tester);

      expect(saved()!.notes, isNull);
    });

    testWidgets('removes the block, after asking', (tester) async {
      await pump(tester, blockId: 'block-1');

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // NFR5: no destructive action without confirmation.
      expect(find.text('Remove this exercise?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Remove'));
      await tester.pumpAndSettle();

      expect(programs.days['uid-a/program-1']!.single.blocks, isEmpty);
    });

    testWidgets('cancelling keeps the block', (tester) async {
      await pump(tester, blockId: 'block-1');

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(programs.days['uid-a/program-1']!.single.blocks, hasLength(1));
    });
  });
}
