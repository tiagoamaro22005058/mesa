import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/app/app.dart';
import 'package:mesa/features/auth/providers/auth_providers.dart';
import 'package:mesa/l10n/app_localizations.dart';

import 'fakes.dart';

/// Boots the real [MesaApp] — router, redirect and all — against fake
/// repositories.
///
/// The overrides are what keep Firebase out of the widget tests: nothing ever
/// reads `authRepositoryProvider`'s real implementation, so no plugin channel
/// is touched and no `Firebase.initializeApp` is needed.
///
/// Pass `settle: false` when the app is expected to sit on the splash — its
/// progress indicator animates forever, so `pumpAndSettle` would time out
/// rather than fail on the assertion the test is actually making.
Future<void> pumpApp(
  WidgetTester tester, {
  required FakeAuthRepository auth,
  required FakeUserProfileRepository profiles,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        userProfileRepositoryProvider.overrideWithValue(profiles),
      ],
      child: const MesaApp(),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Pumps a single screen with the app's localisations in place, for tests that
/// do not need routing.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget child, {
  required FakeAuthRepository auth,
  required FakeUserProfileRepository profiles,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        userProfileRepositoryProvider.overrideWithValue(profiles),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
