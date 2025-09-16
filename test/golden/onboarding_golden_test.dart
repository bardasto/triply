import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_ai_new/presentation/screens/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('Onboarding welcome golden', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    await expectLater(
      find.byType(OnboardingScreen),
      matchesGoldenFile('goldens/onboarding_welcome.png'),
    );
  });
}
