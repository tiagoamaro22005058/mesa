import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mesa/features/auth/presentation/password_reset_screen.dart';
import 'package:mesa/features/auth/presentation/sign_in_screen.dart';
import 'package:mesa/features/auth/presentation/sign_up_screen.dart';
import 'package:mesa/features/auth/presentation/splash_screen.dart';
import 'package:mesa/features/auth/providers/auth_providers.dart';
import 'package:mesa/features/catalog/presentation/catalog_screen.dart';
import 'package:mesa/features/catalog/presentation/custom_exercise_form_screen.dart';
import 'package:mesa/features/catalog/presentation/exercise_detail_screen.dart';
import 'package:mesa/features/home/presentation/home_screen.dart';
import 'package:mesa/features/settings/presentation/profile_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

/// Route names, referenced by `goNamed` rather than raw paths.
abstract final class Routes {
  static const home = 'home';
  static const profile = 'profile';
  static const catalog = 'catalog';
  static const exerciseDetail = 'exerciseDetail';
  static const customExerciseNew = 'customExerciseNew';
  static const customExerciseEdit = 'customExerciseEdit';
  static const signIn = 'signIn';
  static const signUp = 'signUp';
  static const passwordReset = 'passwordReset';
  static const splash = 'splash';
}

/// Paths, kept next to the names so the redirect can compare against them.
abstract final class Paths {
  static const home = '/';
  static const profile = '/profile';
  static const catalog = '/catalog';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const passwordReset = '/reset-password';
  static const splash = '/splash';

  /// The only screens an unauthenticated user may reach (F1).
  static const Set<String> unauthenticated = {signIn, signUp, passwordReset};
}

/// The application router.
///
/// Auth state gates every route through [redirect]. The router itself is built
/// once and refreshed through a [Listenable] rather than rebuilt on each auth
/// change — recreating the `GoRouter` would throw away navigation state.
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final refresh = _AuthRefreshListenable();
  ref.listen(authStateProvider, (_, _) => refresh.refresh());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Paths.splash,
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(ref, state.matchedLocation),
    routes: [
      GoRoute(
        path: Paths.splash,
        name: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Paths.signIn,
        name: Routes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: Paths.signUp,
        name: Routes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: Paths.passwordReset,
        name: Routes.passwordReset,
        builder: (context, state) => const PasswordResetScreen(),
      ),
      GoRoute(
        path: Paths.home,
        name: Routes.home,
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            name: Routes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: 'catalog',
            name: Routes.catalog,
            builder: (context, state) => const CatalogScreen(),
            routes: [
              // Before ':id', so `/catalog/new` is not read as an exercise
              // whose id is "new".
              GoRoute(
                path: 'new',
                name: Routes.customExerciseNew,
                builder: (context, state) => const CustomExerciseFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: Routes.exerciseDetail,
                builder: (context, state) =>
                    ExerciseDetailScreen(exerciseId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: Routes.customExerciseEdit,
                    builder: (context, state) =>
                        CustomExerciseFormScreen(exerciseId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Where a request for [location] should actually go, given the auth state.
///
/// Returns `null` to allow the requested location.
String? _redirect(Ref ref, String location) {
  final auth = ref.read(authStateProvider);

  // Firebase has not reported yet. Hold on the splash rather than guess —
  // guessing "signed out" is what makes an app flash its sign-in screen at
  // someone who is already signed in (F1).
  if (auth.isLoading && !auth.hasValue) {
    return location == Paths.splash ? null : Paths.splash;
  }

  // A stream error is treated as signed out. There is no session to trust, and
  // stranding the user on a splash with no way forward would be worse.
  final signedIn = auth.value != null;
  final onAuthScreen = Paths.unauthenticated.contains(location);

  if (!signedIn) {
    return onAuthScreen ? null : Paths.signIn;
  }
  if (onAuthScreen || location == Paths.splash) {
    return Paths.home;
  }
  return null;
}

/// Bridges Riverpod's auth stream to `go_router`'s [Listenable]-based refresh.
class _AuthRefreshListenable extends ChangeNotifier {
  void refresh() => notifyListeners();
}
