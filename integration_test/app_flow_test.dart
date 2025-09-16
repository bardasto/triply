// integration_test/app_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:travel_ai_new/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Onboarding -> Next -> Login', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Welcome
    expect(find.text('Get started'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // Слайдер: клик по Next один раз (или несколько при необходимости)
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Переход на Login
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back!'), findsOneWidget);
  });
}
