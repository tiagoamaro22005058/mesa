import 'package:flutter/material.dart';

/// Shown while Firebase restores a persisted session.
///
/// Exists so a cold start never flashes the sign-in screen at a user who is
/// already signed in (F1). Usually visible for a frame or two.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
