import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/app/app.dart';

void main() {
  testWidgets('app boots to the placeholder home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MesaApp()));
    await tester.pumpAndSettle();

    expect(find.text('Scaffold ready'), findsOneWidget);
  });

  testWidgets('app uses the dark theme by default', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MesaApp()));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
