import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mesa/app/router.dart';
import 'package:mesa/app/theme.dart';
import 'package:mesa/features/auth/providers/auth_providers.dart';
import 'package:mesa/l10n/app_localizations.dart';

/// Root widget. Owns theming, localisation and routing.
class MesaApp extends ConsumerWidget {
  const MesaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Activates the listener that creates `users/{uid}` on first sign-in.
    // Nothing consumes its value; it has to be watched by something to run.
    ref.watch(profileBootstrapProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Dark by default (NFR6); F8 turns this into a user setting.
      themeMode: ThemeMode.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
