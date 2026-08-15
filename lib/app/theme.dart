import 'package:flutter/material.dart';

/// Application theming.
///
/// Dark is the default (NFR6) — the app is used in gym lighting. Both schemes
/// are built from one seed so light mode stays available as a settings toggle
/// (F8) without a second palette to maintain.
abstract final class AppTheme {
  /// Seed for the Material 3 colour schemes.
  static const Color _seed = Color(0xFF4C6EF5);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      // NFR4: tap targets stay at or above 48dp — primary actions are used
      // mid-set, one-handed.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
      ),
    );
  }
}
