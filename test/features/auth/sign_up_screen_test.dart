import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/core/failures/auth_failure.dart';
import 'package:mesa/features/auth/presentation/password_reset_screen.dart';
import 'package:mesa/features/auth/presentation/sign_up_screen.dart';

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

  Future<void> fillSignUp(
    WidgetTester tester, {
    String name = 'Tiago',
    String email = 'tiago@example.com',
    String password = 'hunter2',
    String? confirm,
  }) async {
    await tester.enterText(find.byType(TextFormField).at(0), name);
    await tester.enterText(find.byType(TextFormField).at(1), email);
    await tester.enterText(find.byType(TextFormField).at(2), password);
    await tester.enterText(find.byType(TextFormField).at(3), confirm ?? password);
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
  }

  group('sign-up', () {
    Future<void> pump(WidgetTester tester) =>
        pumpScreen(tester, const SignUpScreen(), auth: auth, profiles: profiles);

    testWidgets('requires every field', (tester) async {
      await pump(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your name'), findsOneWidget);
      expect(find.text('Enter your email address'), findsOneWidget);
      expect(find.text('Enter a password'), findsOneWidget);
      expect(auth.calls, isEmpty);
    });

    testWidgets('enforces the six-character password minimum', (tester) async {
      await pump(tester);

      await fillSignUp(tester, password: 'abc');

      expect(find.text('Use at least six characters'), findsOneWidget);
      expect(auth.calls, isEmpty);
    });

    testWidgets('catches a mistyped confirmation', (tester) async {
      await pump(tester);

      await fillSignUp(tester, password: 'hunter2', confirm: 'hunter3');

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(auth.calls, isEmpty);
    });

    testWidgets('creates the account with a trimmed name and email', (
      tester,
    ) async {
      await pump(tester);

      await fillSignUp(tester, name: '  Tiago  ', email: ' tiago@example.com ');

      expect(auth.calls, ['signUpWithEmail:tiago@example.com']);
      expect(auth.currentUser?.displayName, 'Tiago');
    });

    testWidgets('reports an address that already has an account', (tester) async {
      auth.nextFailure = const AuthFailure(AuthFailureKind.emailInUse);
      await pump(tester);

      await fillSignUp(tester);

      expect(
        find.text('That email address already has an account.'),
        findsOneWidget,
      );
    });
  });

  group('password reset', () {
    Future<void> pump(WidgetTester tester) => pumpScreen(
      tester,
      const PasswordResetScreen(),
      auth: auth,
      profiles: profiles,
    );

    testWidgets('requires a valid address', (tester) async {
      await pump(tester);

      await tester.enterText(find.byType(TextFormField), 'nope');
      await tester.tap(find.widgetWithText(FilledButton, 'Reset password'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(auth.calls, isEmpty);
    });

    testWidgets('confirms without revealing whether the account exists', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(find.byType(TextFormField), 'tiago@example.com');
      await tester.tap(find.widgetWithText(FilledButton, 'Reset password'));
      await tester.pumpAndSettle();

      expect(auth.calls, ['sendPasswordResetEmail:tiago@example.com']);
      expect(
        find.text('If that address has an account, a reset link is on its way.'),
        findsOneWidget,
      );
    });

    testWidgets('does not confirm when the request failed', (tester) async {
      auth.nextFailure = const AuthFailure(AuthFailureKind.networkUnavailable);
      await pump(tester);

      await tester.enterText(find.byType(TextFormField), 'tiago@example.com');
      await tester.tap(find.widgetWithText(FilledButton, 'Reset password'));
      await tester.pumpAndSettle();

      expect(
        find.text('If that address has an account, a reset link is on its way.'),
        findsNothing,
      );
      expect(
        find.text('No connection. Signing in is the one thing that needs it.'),
        findsOneWidget,
      );
    });
  });
}
