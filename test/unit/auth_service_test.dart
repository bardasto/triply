import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_ai_new/data/services/auth_service.dart';
import '../helpers/mocks.dart';

void main() {
  test('AuthService.signUpWithEmail maps user_already_registered', () async {
    final mockClient = MockSupabaseClient();
    final mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        )).thenThrow(const AuthException(
      'User already registered',
      statusCode: 'user_already_registered',
    ));

    final service = AuthService(client: mockClient);

    expect(
      () => service.signUpWithEmail(
        email: 'a@a.com',
        password: 'P@ssw0rd',
        displayName: 'A',
      ),
      throwsA(predicate(
          (e) => e.toString().contains('This email is already in use'))),
    );
  });
}
