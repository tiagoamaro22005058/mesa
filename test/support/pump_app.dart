import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mesa/app/app.dart';
import 'package:mesa/app/router.dart';
import 'package:mesa/features/auth/providers/auth_providers.dart';
import 'package:mesa/features/catalog/providers/catalog_providers.dart';
import 'package:mesa/l10n/app_localizations.dart';

import 'fakes.dart';

/// Wraps [child] in the provider overrides every widget test shares.
///
/// This is what keeps Firebase out of them: nothing ever reads a real
/// implementation, so no plugin channel is touched and no
/// `Firebase.initializeApp` is needed. The catalogue is faked for the same
/// reason plus one more — the real asset is 1.1 MB, and parsing it per test
/// would cost more than the tests do.
///
/// Returns the scope rather than the override list because Riverpod 3 does not
/// export `Override`, so the list has no nameable type.
Widget _scoped({
  required Widget child,
  required FakeAuthRepository auth,
  required FakeUserProfileRepository profiles,
  FakeExerciseCatalog? catalog,
  FakeCustomExerciseRepository? customExercises,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      userProfileRepositoryProvider.overrideWithValue(profiles),
      exerciseCatalogProvider.overrideWithValue(catalog ?? FakeExerciseCatalog()),
      customExerciseRepositoryProvider.overrideWithValue(
        customExercises ?? FakeCustomExerciseRepository(),
      ),
    ],
    child: _ResolvedAuth(child: child),
  );
}

/// Holds a subscription to [authStateProvider] above the screen under test.
///
/// In the real app the router's redirect watches auth before any screen is
/// built, so `ref.read(authStateProvider).value` always has a uid by the time a
/// button is tapped. A test pumping one screen in isolation has nothing
/// watching it, so the provider is created on first read and its first value
/// arrives a microtask too late — and a controller that checks the uid
/// silently does nothing. Without this the harness would fail screens that
/// work.
class _ResolvedAuth extends ConsumerWidget {
  const _ResolvedAuth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStateProvider);
    return child;
  }
}

/// Boots the real [MesaApp] — router, redirect and all — against fakes.
///
/// Pass `settle: false` when the app is expected to sit on the splash — its
/// progress indicator animates forever, so `pumpAndSettle` would time out
/// rather than fail on the assertion the test is actually making.
Future<void> pumpApp(
  WidgetTester tester, {
  required FakeAuthRepository auth,
  required FakeUserProfileRepository profiles,
  FakeExerciseCatalog? catalog,
  FakeCustomExerciseRepository? customExercises,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    _scoped(
      auth: auth,
      profiles: profiles,
      catalog: catalog,
      customExercises: customExercises,
      child: const MesaApp(),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Pumps a single screen with a real [GoRouter] above it.
///
/// For the screens that navigate as part of what they do — deleting a custom
/// exercise leaves the detail screen, saving one opens it. Those call
/// `GoRouter.of(context)`, which throws under a plain [MaterialApp], and a test
/// that worked around it would stop covering the navigation.
///
/// The destinations are stubs: this asserts that the screen navigates, not
/// where it lands. `router.dart` and its redirect test own the route tree.
Future<void> pumpRoutedScreen(
  WidgetTester tester,
  Widget child, {
  required FakeAuthRepository auth,
  required FakeUserProfileRepository profiles,
  FakeExerciseCatalog? catalog,
  FakeCustomExerciseRepository? customExercises,
}) async {
  const stub = Scaffold(body: SizedBox.shrink());
  final router = GoRouter(
    initialLocation: '/screen',
    routes: [
      GoRoute(path: '/screen', builder: (context, state) => child),
      GoRoute(
        path: '/catalog',
        name: Routes.catalog,
        builder: (context, state) => stub,
        routes: [
          GoRoute(
            path: ':id',
            name: Routes.exerciseDetail,
            builder: (context, state) => stub,
            routes: [
              GoRoute(
                path: 'edit',
                name: Routes.customExerciseEdit,
                builder: (context, state) => stub,
              ),
            ],
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    _scoped(
      auth: auth,
      profiles: profiles,
      catalog: catalog,
      customExercises: customExercises,
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pumps a single screen with the app's localisations in place, for tests that
/// do not need routing.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget child, {
  required FakeAuthRepository auth,
  required FakeUserProfileRepository profiles,
  FakeExerciseCatalog? catalog,
  FakeCustomExerciseRepository? customExercises,
}) async {
  await tester.pumpWidget(
    _scoped(
      auth: auth,
      profiles: profiles,
      catalog: catalog,
      customExercises: customExercises,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
