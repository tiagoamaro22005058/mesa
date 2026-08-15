import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/domain/models/auth_user.dart';
import 'package:mesa/domain/models/body_part.dart';
import 'package:mesa/domain/models/equipment.dart';
import 'package:mesa/domain/models/exercise.dart';
import 'package:mesa/domain/models/load_model.dart';
import 'package:mesa/domain/models/muscle.dart';
import 'package:mesa/domain/models/user_profile.dart';
import 'package:mesa/features/catalog/presentation/custom_exercise_form_screen.dart';

import '../../support/exercises.dart';
import '../../support/fakes.dart';
import '../../support/pump_app.dart';

/// F2: "Create/edit/delete custom exercises."
void main() {
  const user = AuthUser(uid: 'uid-a', email: 'a@example.com', displayName: 'Tiago');
  final now = DateTime.utc(2026, 8, 15);

  late FakeAuthRepository auth;
  late FakeUserProfileRepository profiles;
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
    customExercises = FakeCustomExerciseRepository();
    catalog = FakeExerciseCatalog(exercises: [exercise('0025', 'barbell bench press')]);
  });

  tearDown(() async {
    await auth.dispose();
    await profiles.dispose();
    await customExercises.dispose();
  });

  Future<void> pump(WidgetTester tester, {String? exerciseId}) async {
    // A name field, three dropdowns, the derived load model, a multi-line
    // instructions field and Save do not fit the default 800×600 test surface,
    // which leaves the button a few pixels past the bottom edge where a tap
    // cannot reach it. On a phone the user scrolls; here it is simpler to give
    // the test a screen tall enough to hold the form.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpRoutedScreen(
      tester,
      CustomExerciseFormScreen(exerciseId: exerciseId),
      auth: auth,
      profiles: profiles,
      catalog: catalog,
      customExercises: customExercises,
    );
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
  }

  Exercise saved() => customExercises.exercises['uid-a']!.single;

  testWidgets('creates an exercise from the form', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextFormField).first, 'my gym chest press');
    await save(tester);

    expect(saved().name, 'my gym chest press');
    expect(saved().isCustom, isTrue);
  });

  testWidgets('refuses to save without a name', (tester) async {
    await pump(tester);

    await save(tester);

    expect(customExercises.exercises['uid-a'], anyOf(isNull, isEmpty));
  });

  testWidgets('splits the instructions into steps, one per line', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextFormField).first, 'my press');
    await tester.enterText(
      find.byType(TextFormField).last,
      'Sit down.\n\nGrip the handles.\nPress.\n  ',
    );
    await save(tester);

    // Blank lines are dropped rather than becoming empty steps.
    expect(saved().steps, ['Sit down.', 'Grip the handles.', 'Press.']);
  });

  testWidgets('derives the load model from the chosen equipment', (tester) async {
    // §5.6 makes the load model a function of equipment. Letting the user pick
    // a third thing that disagrees is how the M5 maths goes quietly wrong.
    await pump(tester);

    await tester.enterText(find.byType(TextFormField).first, 'weighted dips');
    await tester.tap(find.byType(DropdownButtonFormField<Equipment>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weighted').last);
    await tester.pumpAndSettle();
    await save(tester);

    expect(saved().equipment, Equipment.weighted);
    expect(saved().loadModel, LoadModel.bodyweightPlusLoad);
  });

  testWidgets('shows what the equipment choice means for logging', (tester) async {
    await pump(tester);

    expect(find.text('Logged as: Weight you enter'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<Equipment>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bodyweight').last);
    await tester.pumpAndSettle();

    expect(find.text('Logged as: Bodyweight, tracked by reps'), findsOneWidget);
  });

  testWidgets('gives a custom exercise an id that cannot collide with the catalogue', (tester) async {
    // Catalogue ids are upstream's four digits. A custom one that looked the
    // same could shadow a future catalogue entry.
    await pump(tester);

    await tester.enterText(find.byType(TextFormField).first, 'my press');
    await save(tester);

    expect(saved().id, startsWith('custom-'));
    expect(RegExp(r'^\d{4}$').hasMatch(saved().id), isFalse);
  });

  testWidgets('loads an existing exercise into the form for editing', (tester) async {
    customExercises.exercises['uid-a'] = [
      customExercise(
        'custom-1',
        'my gym press',
        bodyPart: BodyPart.chest,
        primaryMuscle: Muscle.chest,
        equipment: Equipment.leverageMachine,
        steps: const ['Sit down.', 'Press.'],
      ),
    ];

    await pump(tester, exerciseId: 'custom-1');

    expect(find.widgetWithText(TextFormField, 'my gym press'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Sit down.\nPress.'), findsOneWidget);
    expect(find.text('Edit exercise'), findsOneWidget);
  });

  testWidgets('editing keeps the id rather than creating a second exercise', (tester) async {
    customExercises.exercises['uid-a'] = [customExercise('custom-1', 'my gym press')];

    await pump(tester, exerciseId: 'custom-1');
    await tester.enterText(find.byType(TextFormField).first, 'my gym chest press');
    await save(tester);

    expect(customExercises.exercises['uid-a'], hasLength(1));
    expect(saved().id, 'custom-1');
    expect(saved().name, 'my gym chest press');
  });

  testWidgets('says so when editing an exercise that no longer exists', (tester) async {
    await pump(tester, exerciseId: 'deleted-1');

    expect(find.text('That exercise no longer exists.'), findsOneWidget);
  });
}
