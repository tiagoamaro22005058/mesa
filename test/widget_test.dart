import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/domain/models/auth_user.dart';
import 'package:mesa/features/auth/presentation/sign_in_screen.dart';
import 'package:mesa/features/home/presentation/home_screen.dart';

import 'support/fakes.dart';
import 'support/pump_app.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeUserProfileRepository profiles;

  setUp(() {
    profiles = FakeUserProfileRepository();
  });

  tearDown(() async {
    await auth.dispose();
    await profiles.dispose();
  });

  testWidgets('app boots to the sign-in screen when signed out', (tester) async {
    auth = FakeAuthRepository();

    await pumpApp(tester, auth: auth, profiles: profiles);

    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('app boots to home when a session is restored', (tester) async {
    auth = FakeAuthRepository(
      initialUser: const AuthUser(uid: 'uid-a', displayName: 'Tiago'),
    );

    await pumpApp(tester, auth: auth, profiles: profiles);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Signed in as Tiago'), findsOneWidget);
  });

  testWidgets('app uses the dark theme by default', (tester) async {
    auth = FakeAuthRepository();

    await pumpApp(tester, auth: auth, profiles: profiles);

    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('signing out from home returns to sign-in', (tester) async {
    auth = FakeAuthRepository(
      initialUser: const AuthUser(uid: 'uid-a', displayName: 'Tiago'),
    );
    await pumpApp(tester, auth: auth, profiles: profiles);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(auth.calls, contains('signOut'));
    expect(find.byType(SignInScreen), findsOneWidget);
  });
}
