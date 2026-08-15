import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mesa/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase.initializeApp() lands here once `flutterfire configure` has
  // generated lib/firebase_options.dart for the dev and prod projects.

  runApp(const ProviderScope(child: MesaApp()));
}
