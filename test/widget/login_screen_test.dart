import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';

import 'package:travel_ai_new/data/services/auth_service.dart';
import 'package:travel_ai_new/providers/auth_provider.dart';
import 'package:travel_ai_new/presentation/screens/auth/login_screen.dart';
import '../helpers/mocks.dart';

void main() {
  testWidgets('Login shows validators for empty fields', (tester) async {
    final mockClient = MockSupabaseClient();
    final mockAuth = MockGoTrueClient();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.onAuthStateChange)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockAuth.currentSession).thenReturn(null);
    when(() => mockAuth.currentUser).thenReturn(null);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(auth: AuthService(client: mockClient)),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });
}
