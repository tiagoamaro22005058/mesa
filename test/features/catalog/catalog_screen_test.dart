import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/core/failures/catalog_failure.dart';
import 'package:mesa/domain/models/auth_user.dart';
import 'package:mesa/domain/models/body_part.dart';
import 'package:mesa/domain/models/equipment.dart';
import 'package:mesa/domain/models/user_profile.dart';
import 'package:mesa/features/catalog/presentation/catalog_screen.dart';
import 'package:mesa/features/catalog/presentation/widgets/exercise_filters_sheet.dart';
import 'package:mesa/features/catalog/presentation/widgets/exercise_list_tile.dart';

import '../../support/exercises.dart';
import '../../support/fakes.dart';
import '../../support/pump_app.dart';

/// F2: "Browse and search the bundled catalogue… filter by body part, primary
/// muscle and equipment… custom exercises appear inline in search results,
/// visually marked… favourites."
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
        exercise('0025', 'barbell bench press', aliases: ['supino reto']),
        exercise(
          '0043',
          'barbell full squat',
          aliases: ['agachamento livre'],
          bodyPart: BodyPart.upperLegs,
        ),
        exercise('0334', 'dumbbell lateral raise', equipment: Equipment.dumbbell),
      ],
    );
  });

  tearDown(() async {
    await auth.dispose();
    await profiles.dispose();
    await customExercises.dispose();
  });

  Future<void> pump(WidgetTester tester) => pumpScreen(
    tester,
    const CatalogScreen(),
    auth: auth,
    profiles: profiles,
    catalog: catalog,
    customExercises: customExercises,
  );

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pumpAndSettle();
  }

  /// Opens the filter sheet and taps a chip.
  ///
  /// The equipment group sits below nine body parts and twenty-four muscles,
  /// and a `ListView` does not build what is off screen — so the chip has to be
  /// scrolled to rather than merely found.
  Future<void> tapFilterChip(WidgetTester tester, String label) async {
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    final chip = find.widgetWithText(FilterChip, label);
    await tester.scrollUntilVisible(
      chip,
      200,
      scrollable: find.descendant(
        of: find.byType(ExerciseFiltersSheet),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Show results'));
    await tester.pumpAndSettle();
  }

  testWidgets('lists the whole catalogue before anything is typed', (tester) async {
    await pump(tester);

    expect(find.byType(ExerciseListTile), findsNWidgets(3));
    expect(find.text('3 exercises'), findsOneWidget);
  });

  testWidgets('titles are rendered title-cased, not as upstream stores them', (tester) async {
    // §5.3: upstream is lowercase, and title-casing happens at render.
    await pump(tester);

    expect(find.text('Barbell Bench Press'), findsOneWidget);
  });

  testWidgets('narrows to what was searched', (tester) async {
    await pump(tester);

    await search(tester, 'squat');

    expect(find.byType(ExerciseListTile), findsOneWidget);
    expect(find.text('Barbell Full Squat'), findsOneWidget);
  });

  testWidgets('finds an exercise by its Portuguese alias', (tester) async {
    await pump(tester);

    await search(tester, 'agachamento');

    expect(find.text('Barbell Full Squat'), findsOneWidget);
  });

  testWidgets('offers a way out when nothing matches', (tester) async {
    await pump(tester);

    await search(tester, 'kayaking');

    expect(find.byType(ExerciseListTile), findsNothing);
    expect(find.text('Nothing matches'), findsOneWidget);
  });

  testWidgets('shows a custom exercise inline, marked as custom', (tester) async {
    customExercises.exercises['uid-a'] = [customExercise('custom-1', 'my gym press')];

    await pump(tester);
    await search(tester, 'press');

    expect(find.text('My Gym Press'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
    // The catalogue's bench press is in the same list, unmarked.
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.byType(ExerciseListTile), findsNWidgets(2));
  });

  testWidgets('a newly created custom exercise becomes searchable at once', (tester) async {
    await pump(tester);

    await customExercises.save('uid-a', customExercise('custom-1', 'my gym press'));
    await tester.pumpAndSettle();
    await search(tester, 'my gym');

    expect(find.text('My Gym Press'), findsOneWidget);
  });

  testWidgets('starring an exercise writes it to the profile', (tester) async {
    await pump(tester);

    await tester.tap(find.byIcon(Icons.star_border).first);
    await tester.pumpAndSettle();

    expect(profiles.profiles['uid-a']!.favouriteExerciseIds, ['0025']);
    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('unstarring removes it again', (tester) async {
    profiles.profiles['uid-a'] = profiles.profiles['uid-a']!.toggleFavourite('0025');

    await pump(tester);
    await tester.tap(find.byIcon(Icons.star).first);
    await tester.pumpAndSettle();

    expect(profiles.profiles['uid-a']!.favouriteExerciseIds, isEmpty);
  });

  testWidgets('filters by equipment through the sheet', (tester) async {
    await pump(tester);

    await tapFilterChip(tester, 'Dumbbell');

    expect(find.byType(ExerciseListTile), findsOneWidget);
    expect(find.text('Dumbbell Lateral Raise'), findsOneWidget);
  });

  testWidgets('filters by body part', (tester) async {
    await pump(tester);

    await tapFilterChip(tester, 'Upper legs');

    expect(find.byType(ExerciseListTile), findsOneWidget);
    expect(find.text('Barbell Full Squat'), findsOneWidget);
  });

  testWidgets('the filter button counts what is active', (tester) async {
    await pump(tester);

    await tapFilterChip(tester, 'Dumbbell');

    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('narrows to favourites when asked', (tester) async {
    profiles.profiles['uid-a'] = profiles.profiles['uid-a']!.toggleFavourite('0043');

    await pump(tester);
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SwitchListTile, 'Favourites only'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Show results'));
    await tester.pumpAndSettle();

    expect(find.byType(ExerciseListTile), findsOneWidget);
    expect(find.text('Barbell Full Squat'), findsOneWidget);
  });

  testWidgets('reports a catalogue that never shipped, without offering a retry', (tester) async {
    // A packaging fault, not a network one — NFR1 means there is nothing to
    // retry, so the screen says what happened and stops.
    catalog.failure = const CatalogFailure(CatalogFailureKind.assetMissing);

    await pump(tester);

    expect(find.text('The exercise catalogue could not be loaded.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Try again'), findsNothing);
  });

  testWidgets('parses the catalogue once, not on every rebuild', (tester) async {
    // NFR3: the parse is kept alive, so searching does not re-read the asset.
    await pump(tester);

    await search(tester, 'squat');
    await search(tester, 'bench');

    expect(catalog.loadCount, 1);
  });
}
