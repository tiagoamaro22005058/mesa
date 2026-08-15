import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/domain/models/auth_user.dart';
import 'package:mesa/domain/models/user_profile.dart';
import 'package:mesa/features/auth/presentation/sign_in_screen.dart';
import 'package:mesa/features/settings/presentation/profile_screen.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

/// NFR6: "respects system text scaling".
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

  for (final scale in [1.0, 2.0]) {
    testWidgets('sign-in survives ${scale}x text scaling', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpScreen(
        tester,
        const SignInScreen(),
        auth: auth,
        profiles: profiles,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('home survives ${scale}x text scaling', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpApp(tester, auth: auth, profiles: profiles);

      expect(tester.takeException(), isNull);
    });

    testWidgets('profile survives ${scale}x text scaling', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpScreen(
        tester,
        const ProfileScreen(),
        auth: auth,
        profiles: profiles,
      );

      expect(tester.takeException(), isNull);
    });
  }
}
