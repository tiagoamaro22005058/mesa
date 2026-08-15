import 'package:cloud_firestore/cloud_firestore.dart';
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

  // On by default on Android, but NFR1 rests entirely on it — every feature
  // except sign-in has to work with no network — so it is stated rather than
  // inherited. Unlimited cache: a year of sessions is a few MB, and evicting
  // history mid-workout in a basement gym is the failure worth avoiding.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
}
