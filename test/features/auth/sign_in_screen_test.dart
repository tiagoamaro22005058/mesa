import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/core/failures/auth_failure.dart';
import 'package:mesa/features/auth/presentation/sign_in_screen.dart';

import '../../support/fakes.dart';
import '../../support/pump_app.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeUserProfileRepository profiles;

  setUp(() {
    auth = FakeAuthRepository();
    profiles = FakeUserProfileRepository();
  });

  tearDown(() async {
    await auth.dispose();
    await profiles.dispose();
  });

  Future<void> pump(WidgetTester tester) =>
      pumpScreen(tester, const SignInScreen(), auth: auth, profiles: profiles);

  Future<void> fillAndSubmit(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
  }

  testWidgets('rejects an empty form without calling the repository', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter a password'), findsOneWidget);
    expect(auth.calls, isEmpty);
  });

  testWidgets('rejects a malformed email address', (tester) async {
    await pump(tester);

    await fillAndSubmit(tester, email: 'not-an-email', password: 'hunter2');

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(auth.calls, isEmpty);
  });

  testWidgets('accepts an existing short password', (tester) async {
    // The six-character minimum applies at sign-up. Enforcing it here would
    // lock out an account created before the rule existed.
    await pump(tester);

    await fillAndSubmit(tester, email: 'a@example.com', password: 'abc');

    expect(auth.calls, ['signInWithEmail:a@example.com']);
  });

  testWidgets('submits trimmed credentials', (tester) async {
    await pump(tester);

    await fillAndSubmit(tester, email: '  a@example.com  ', password: 'hunter2');

    expect(auth.calls, ['signInWithEmail:a@example.com']);
  });

  testWidgets('renders a failure without leaking the exception', (tester) async {
    auth.nextFailure = const AuthFailure(AuthFailureKind.invalidCredentials);
    await pump(tester);

    await fillAndSubmit(tester, email: 'a@example.com', password: 'wrong');

    expect(
      find.text('That email and password do not match an account.'),
      findsOneWidget,
    );
  });

  testWidgets('says so plainly when there is no connection', (tester) async {
    auth.nextFailure = const AuthFailure(AuthFailureKind.networkUnavailable);
    await pump(tester);

    await fillAndSubmit(tester, email: 'a@example.com', password: 'hunter2');

    expect(
      find.text('No connection. Signing in is the one thing that needs it.'),
      findsOneWidget,
    );
  });

  testWidgets('stays silent when the user backs out of Google Sign-In', (
    tester,
  ) async {
    auth.nextFailure = const AuthFailure(AuthFailureKind.cancelled);
    await pump(tester);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(auth.calls, ['signInWithGoogle']);
    expect(
      find.text('Something went wrong. Try again.'),
      findsNothing,
      reason: 'dismissing the account picker is a decision, not an error',
    );
  });

  testWidgets('starts Google Sign-In on tap', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(auth.calls, ['signInWithGoogle']);
  });
}
