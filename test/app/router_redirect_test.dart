import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/domain/models/auth_user.dart';
import 'package:mesa/features/auth/presentation/password_reset_screen.dart';
import 'package:mesa/features/auth/presentation/sign_in_screen.dart';
import 'package:mesa/features/auth/presentation/sign_up_screen.dart';
import 'package:mesa/features/auth/presentation/splash_screen.dart';
import 'package:mesa/features/home/presentation/home_screen.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

/// F1: "Auth state drives routing: unauthenticated users only reach auth
/// screens."
void main() {
  const user = AuthUser(uid: 'uid-a', email: 'a@example.com', displayName: 'A');

  late FakeAuthRepository auth;
  late FakeUserProfileRepository profiles;

  setUp(() {
    profiles = FakeUserProfileRepository();
  });

  tearDown(() async {
    await auth.dispose();
    await profiles.dispose();
  });

  testWidgets('holds on the splash until auth state is known', (tester) async {
    auth = FakeAuthRepository(emitInitialState: false);

    await pumpApp(tester, auth: auth, profiles: profiles, settle: false);

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(
      find.byType(SignInScreen),
      findsNothing,
      reason: 'a cold start must not flash sign-in at an already-signed-in user',
    );
  });

  testWidgets('sends an unauthenticated user to sign-in', (tester) async {
    auth = FakeAuthRepository();

    await pumpApp(tester, auth: auth, profiles: profiles);

    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('lets an unauthenticated user reach the other auth screens', (
    tester,
  ) async {
    auth = FakeAuthRepository();
    await pumpApp(tester, auth: auth, profiles: profiles);

    await tester.tap(find.text('No account? Create one'));
    await tester.pumpAndSettle();
    expect(find.byType(SignUpScreen), findsOneWidget);

    await tester.tap(find.text('Already have an account? Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forgot your password?'));
    await tester.pumpAndSettle();
    expect(find.byType(PasswordResetScreen), findsOneWidget);
  });

  testWidgets('restores a persisted session straight to home', (tester) async {
    auth = FakeAuthRepository(initialUser: user);

    await pumpApp(tester, auth: auth, profiles: profiles);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SignInScreen), findsNothing);
  });

  testWidgets('moves to home the moment a user signs in', (tester) async {
    auth = FakeAuthRepository();
    await pumpApp(tester, auth: auth, profiles: profiles);
    expect(find.byType(SignInScreen), findsOneWidget);

    auth.emit(user);
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('bounces back to sign-in on sign-out', (tester) async {
    auth = FakeAuthRepository(initialUser: user);
    await pumpApp(tester, auth: auth, profiles: profiles);
    expect(find.byType(HomeScreen), findsOneWidget);

    auth.emit(null);
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('creates the profile document on first authentication', (
    tester,
  ) async {
    auth = FakeAuthRepository();
    await pumpApp(tester, auth: auth, profiles: profiles);
    expect(profiles.profiles, isEmpty);

    auth.emit(user);
    await tester.pumpAndSettle();

    expect(profiles.profiles.keys, ['uid-a']);
    expect(profiles.profiles['uid-a']!.displayName, 'A');
  });

  testWidgets('falls back to the email local part when there is no name', (
    tester,
  ) async {
    auth = FakeAuthRepository();
    await pumpApp(tester, auth: auth, profiles: profiles);

    auth.emit(const AuthUser(uid: 'uid-b', email: 'tiago@example.com'));
    await tester.pumpAndSettle();

    expect(profiles.profiles['uid-b']!.displayName, 'tiago');
  });
}
