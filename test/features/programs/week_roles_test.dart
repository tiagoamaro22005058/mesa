// F3: "Configure week roles: add/remove/reorder, edit RPE target and volume
// multiplier per role."
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/domain/models/auth_user.dart';
import 'package:mesa/domain/models/user_profile.dart';
import 'package:mesa/domain/models/week_role.dart';
import 'package:mesa/features/programs/presentation/week_roles_screen.dart';

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

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpRoutedScreen(
      tester,
      const WeekRolesScreen(programId: 'program-1'),
      auth: auth,
      profiles: profiles,
      programs: programs,
    );
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
  }

  List<WeekRole> saved() => programs.programs['uid-a']!.single.weekRoles;

  testWidgets('lists §4\'s mesocycle in order', (tester) async {
    await pump(tester);

    expect(find.text('Base'), findsOneWidget);
    expect(find.text('Intensification'), findsOneWidget);
    expect(find.text('Peak'), findsOneWidget);
    expect(find.text('Deload'), findsOneWidget);

    expect(
      tester.getTopLeft(find.text('Intensification')).dy,
      lessThan(tester.getTopLeft(find.text('Deload')).dy),
    );
  });

  testWidgets('numbers the weeks by position, not by name', (tester) async {
    await pump(tester);

    expect(find.textContaining('Week 1'), findsOneWidget);
    expect(find.textContaining('Week 4'), findsOneWidget);
  });

  testWidgets('renders targets without trailing noise', (tester) async {
    // formatWeight is the app's only decimal renderer (§9.1), so a multiplier
    // of exactly 1 reads as `1` rather than `1.0`.
    await pump(tester);

    expect(find.textContaining('RPE 7 · 1 volume'), findsOneWidget);
    expect(find.textContaining('RPE 5.5 · 0.5 volume'), findsOneWidget);
  });

  testWidgets('adds a week', (tester) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Add week'));
    await tester.pumpAndSettle();
    await save(tester);

    expect(saved(), hasLength(5));
  });

  testWidgets('removes a week', (tester) async {
    await pump(tester);

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
    await save(tester);

    expect(saved(), hasLength(3));
    expect(saved().first.role, WeekRoleKind.intensification);
  });

  testWidgets('edits a week\'s RPE target and volume', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Base'));
    await tester.pumpAndSettle();

    // RPE is a dropdown rather than a text field: a closed half-point
    // vocabulary with nothing to parse and nothing to mistype (NFR4).
    await tester.tap(find.byType(DropdownButtonFormField<double>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7.5').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Volume'), '0,8');
    await tester.tap(find.widgetWithText(FilledButton, 'Save').last);
    await tester.pumpAndSettle();

    await save(tester);

    expect(saved().first.rpeTarget, 7.5);
    // A comma is a legal decimal separator (§9.1, NFR7).
    expect(saved().first.volumeMultiplier, 0.8);
  });

  testWidgets('a mesocycle may hold the same role twice', (tester) async {
    // A2 makes the roles user-configurable, and two base weeks is ordinary.
    // Position is a week's identity, not its name.
    programs.programs['uid-a'] = [
      program(
        'program-1',
        'PPL',
        weekRoles: const [
          WeekRole(role: WeekRoleKind.base, rpeTarget: 7, volumeMultiplier: 1),
          WeekRole(role: WeekRoleKind.base, rpeTarget: 7.5, volumeMultiplier: 1),
        ],
      ),
    ];

    await pump(tester);

    expect(find.text('Base'), findsNWidgets(2));
    expect(find.textContaining('Week 1'), findsOneWidget);
    expect(find.textContaining('Week 2'), findsOneWidget);
  });

  testWidgets('a drag reorders the mesocycle', (tester) async {
    await pump(tester);

    final handle = find.byIcon(Icons.drag_handle).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 100));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    await save(tester);

    expect(saved().map((role) => role.role), [
      WeekRoleKind.intensification,
      WeekRoleKind.base,
      WeekRoleKind.peak,
      WeekRoleKind.deload,
    ]);
  });

  testWidgets('edits are held locally until saved', (tester) async {
    // Reordering four weeks would otherwise cost four document writes (NFR2).
    await pump(tester);

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    expect(
      programs.programs['uid-a']!.single.weekRoles,
      hasLength(4),
      reason: 'nothing written until Save',
    );
  });

  testWidgets('says so when every week has been removed', (tester) async {
    programs.programs['uid-a'] = [
      program('program-1', 'PPL', weekRoles: const []),
    ];

    await pump(tester);

    expect(find.text('No weeks yet'), findsOneWidget);
  });
}
