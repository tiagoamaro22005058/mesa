import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mesa/features/home/presentation/home_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

/// Route names, referenced by `goNamed` rather than raw paths.
abstract final class Routes {
  static const home = 'home';
}

/// The application router.
///
/// M1 attaches auth state here so unauthenticated users only reach the auth
/// screens (F1).
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: Routes.home,
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen(),
      ),
    ],
  );
}
