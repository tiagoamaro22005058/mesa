import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/domain/models/auth_user.dart';
import 'package:mesa/domain/models/equipment.dart';
import 'package:mesa/domain/models/muscle.dart';
import 'package:mesa/domain/models/user_profile.dart';
import 'package:mesa/features/catalog/presentation/exercise_detail_screen.dart';

import '../../support/exercises.dart';
import '../../support/fakes.dart';
import '../../support/pump_app.dart';

/// F2: "Detail screen: instructions, muscles, images."
///
/// Personal history and the e1RM chart are the two F2 bullets deliberately not
/// here — `exerciseStats` has no writer until M4 and charts are M6.
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
    catalog = FakeExerciseCatalog(
      exercises: [
        exercise(
          '0025',
          'barbell bench press',
          primaryMuscle: Muscle.chest,
          synergist: Muscle.triceps,
          secondaryMuscles: [Muscle.triceps, Muscle.delts],
          equipment: Equipment.barbell,
          steps: const ['Lie on the bench.', 'Press the bar.'],
        ),
      ],
    );
  });

  tearDown(() async {
    await auth.dispose();
    await profiles.dispose();
    await customExercises.dispose();
  });

  Future<void> pump(WidgetTester tester, String id) => pumpRoutedScreen(
    tester,
    ExerciseDetailScreen(exerciseId: id),
    auth: auth,
    profiles: profiles,
    catalog: catalog,
    customExercises: customExercises,
  );

  testWidgets('shows the instructions, numbered', (tester) async {
    await pump(tester, '0025');

    expect(find.text('1. Lie on the bench.'), findsOneWidget);
    expect(find.text('2. Press the bar.'), findsOneWidget);
  });

  testWidgets('shows the muscles it works', (tester) async {
    await pump(tester, '0025');

    expect(find.text('Chest'), findsOneWidget);
    expect(find.text('Triceps'), findsOneWidget);
    expect(find.text('Triceps, Delts'), findsOneWidget);
  });

  testWidgets('shows the equipment and how the exercise is logged', (tester) async {
    // The load model is what §7 turns on, so it is worth showing rather than
    // leaving implicit.
    await pump(tester, '0025');

    expect(find.text('Barbell'), findsOneWidget);
    expect(find.text('Logged as: Weight you enter'), findsOneWidget);
  });

  testWidgets('displays the attribution string', (tester) async {
    // §5.1 makes this a licence obligation wherever the media appears, not a
    // courtesy.
    await pump(tester, '0025');

    final attribution = find.text('© Gym visual — https://gymvisual.com/');
    await tester.scrollUntilVisible(attribution, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(attribution, findsOneWidget);
  });

  testWidgets('has no history section or chart yet', (tester) async {
    // The M2/M4/M6 boundary, asserted rather than assumed: building either now
    // would mean building against a collection nothing writes.
    await pump(tester, '0025');

    expect(find.textContaining('e1RM'), findsNothing);
    expect(find.textContaining('Last performed'), findsNothing);
  });

  testWidgets('stars and unstars from the app bar', (tester) async {
    await pump(tester, '0025');

    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pumpAndSettle();

    expect(profiles.profiles['uid-a']!.favouriteExerciseIds, ['0025']);
    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('offers no edit or delete for a catalogue exercise', (tester) async {
    // The bundled catalogue is read-only reference data.
    await pump(tester, '0025');

    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);
  });

  testWidgets('offers edit and delete for a custom exercise', (tester) async {
    customExercises.exercises['uid-a'] = [customExercise('custom-1', 'my gym press')];

    await pump(tester, 'custom-1');

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('asks before deleting, and does nothing if refused', (tester) async {
    // NFR5: no destructive action without confirmation.
    customExercises.exercises['uid-a'] = [customExercise('custom-1', 'my gym press')];

    await pump(tester, 'custom-1');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete this exercise?'), findsOneWidget);
    expect(find.textContaining('cannot be undone'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(customExercises.exercises['uid-a'], hasLength(1));
  });

  testWidgets('deletes when confirmed', (tester) async {
    customExercises.exercises['uid-a'] = [customExercise('custom-1', 'my gym press')];

    await pump(tester, 'custom-1');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(customExercises.exercises['uid-a'], isEmpty);
  });

  testWidgets('unstars an exercise it deletes', (tester) async {
    // A deleted exercise that stayed starred would leave the favourites filter
    // showing a row that resolves to nothing.
    customExercises.exercises['uid-a'] = [customExercise('custom-1', 'my gym press')];
    profiles.profiles['uid-a'] = profiles.profiles['uid-a']!.toggleFavourite('custom-1');

    await pump(tester, 'custom-1');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(profiles.profiles['uid-a']!.favouriteExerciseIds, isEmpty);
  });

  testWidgets('says so when the exercise no longer exists', (tester) async {
    await pump(tester, 'deleted-1');

    expect(find.text('That exercise no longer exists.'), findsOneWidget);
  });
}
