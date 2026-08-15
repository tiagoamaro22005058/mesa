import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/domain/models/auth_user.dart';
import 'package:mesa/domain/models/unit_system.dart';
import 'package:mesa/domain/models/user_profile.dart';
import 'package:mesa/features/settings/presentation/profile_screen.dart';
import 'package:mesa/features/settings/presentation/widgets/plate_inventory_field.dart';

import '../../support/fakes.dart';
import '../../support/pump_app.dart';

/// F1: "Profile settings: display name, units, bar weight, plate inventory,
/// dumbbell increment."
void main() {
  const user = AuthUser(uid: 'uid-a', email: 'a@example.com', displayName: 'Tiago');
  final now = DateTime.utc(2026, 8, 15);

  late FakeAuthRepository auth;
  late FakeUserProfileRepository profiles;

  setUp(() {
    auth = FakeAuthRepository(initialUser: user);
    profiles = FakeUserProfileRepository();
    profiles.profiles['uid-a'] = UserProfile(
      displayName: 'Tiago',
      createdAt: now,
      updatedAt: now,
    );
  });

  tearDown(() async {
    await auth.dispose();
    await profiles.dispose();
  });

  Future<void> pump(WidgetTester tester) =>
      pumpScreen(tester, const ProfileScreen(), auth: auth, profiles: profiles);

  UserProfile saved() => profiles.profiles['uid-a']!;

  /// Selecting a chip widens it, which can push the form's Save button off the
  /// bottom of the list — and a `ListView` does not build what is off screen,
  /// so it has to be scrolled to rather than merely found.
  Future<void> tapSave(WidgetTester tester) async {
    final save = find.widgetWithText(FilledButton, 'Save');
    await tester.scrollUntilVisible(
      save,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
  }

  testWidgets('shows the stored profile', (tester) async {
    await pump(tester);

    expect(find.widgetWithText(TextFormField, 'Tiago'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '20'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '2'), findsOneWidget);
  });

  testWidgets('offers every standard plate and pre-selects §4 defaults', (
    tester,
  ) async {
    await pump(tester);

    for (final plate in PlateInventoryField.standardPlates) {
      final label = plate == plate.roundToDouble()
          ? plate.toStringAsFixed(0)
          : plate.toString();
      expect(
        find.widgetWithText(FilterChip, label),
        findsOneWidget,
        reason: '$plate should be offered',
      );
    }

    // The default inventory is the standard set minus the 0.5 kg fractional.
    final chips = tester.widgetList<FilterChip>(find.byType(FilterChip));
    expect(chips.where((c) => c.selected).length, 7);
  });

  testWidgets('removing a plate persists the shorter inventory', (tester) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(FilterChip, '1.25'));
    await tester.pumpAndSettle();
    await tapSave(tester);

    expect(saved().plateInventory, [25, 20, 15, 10, 5, 2.5]);
  });

  testWidgets('adding a plate keeps the inventory sorted heaviest first', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(FilterChip, '0.5'));
    await tester.pumpAndSettle();
    await tapSave(tester);

    expect(saved().plateInventory, [25, 20, 15, 10, 5, 2.5, 1.25, 0.5]);
  });

  testWidgets('saves every field', (tester) async {
    await pump(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Tiago'), 'Tiago A');
    await tester.enterText(find.widgetWithText(TextFormField, '20'), '15');
    await tester.enterText(find.widgetWithText(TextFormField, '2'), '2.5');
    await tester.tap(find.text('Pounds'));
    await tester.pumpAndSettle();

    await tapSave(tester);

    final profile = saved();
    expect(profile.displayName, 'Tiago A');
    expect(profile.barWeight, 15);
    expect(profile.dumbbellIncrement, 2.5);
    expect(profile.units, UnitSystem.lb);
    expect(find.text('Profile saved'), findsOneWidget);
  });

  testWidgets('accepts a comma decimal separator', (tester) async {
    // The Portuguese keyboard offers a comma, and rejecting it would read as
    // the app being broken rather than fussy (NFR7).
    await pump(tester);

    await tester.enterText(find.widgetWithText(TextFormField, '20'), '17,5');
    await tapSave(tester);

    expect(saved().barWeight, 17.5);
  });

  testWidgets('refuses a bar weight of zero', (tester) async {
    await pump(tester);

    await tester.enterText(find.widgetWithText(TextFormField, '20'), '0');
    await tapSave(tester);

    expect(find.text('Enter a number above zero'), findsOneWidget);
    expect(saved().barWeight, 20, reason: 'nothing should have been written');
  });

  testWidgets('stamps updatedAt but leaves createdAt alone', (tester) async {
    await pump(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Tiago'), 'Tiago A');
    await tapSave(tester);

    expect(saved().createdAt, now);
    expect(saved().updatedAt.isAfter(now), isTrue);
  });

  testWidgets('shows one account nothing of another account\'s profile', (
    tester,
  ) async {
    profiles.profiles['uid-b'] = UserProfile(
      displayName: 'Someone Else',
      barWeight: 15,
      createdAt: now,
      updatedAt: now,
    );

    await pump(tester);

    expect(find.widgetWithText(TextFormField, 'Tiago'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Someone Else'), findsNothing);
  });
}
