import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:travel_ai_new/presentation/screens/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('Welcome has no dots; after Get started dots appear',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    // На welcome индикатора нет
    expect(find.byType(SmoothPageIndicator), findsNothing);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // После старта индикатор появляется
    expect(find.byType(SmoothPageIndicator), findsOneWidget);
  });
}
