// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mesa';

  @override
  String get homePlaceholderTitle => 'Scaffold ready';

  @override
  String get homePlaceholderBody =>
      'Riverpod, go_router and the theme are wired up. Session logging arrives in M4.';
}
