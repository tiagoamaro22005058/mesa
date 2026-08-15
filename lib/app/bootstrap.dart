import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:flutter/widgets.dart';
import 'package:mesa/firebase_options_dev.dart' as dev;
import 'package:mesa/firebase_options_prod.dart' as prod;

/// Firebase project for a given build flavour.
///
/// Both generated option files declare `DefaultFirebaseOptions`, so they are
/// imported under prefixes. An unrecognised flavour is a build configuration
/// error, not something to paper over with a default — silently booting dev
/// against the prod project is exactly the failure worth being loud about.
FirebaseOptions firebaseOptionsFor(String? flavor) => switch (flavor) {
  'dev' => dev.DefaultFirebaseOptions.currentPlatform,
  'prod' => prod.DefaultFirebaseOptions.currentPlatform,
  _ => throw StateError(
    'No Firebase project is configured for flavour "$flavor". '
    'Build with --flavor dev or --flavor prod.',
  ),
};

/// Prepares the bindings and Firebase before the first frame.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptionsFor(appFlavor));
}
