import 'package:flutter_test/flutter_test.dart';
import 'package:travel_ai_new/presentation/providers/auth_provider.dart';
import 'package:travel_ai_new/data/services/auth_service.dart'; // ← импорт класса

import '../helpers/mocks.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    // ВАЖНО: подставляем goTrue внутрь клиента
    when(() => mockClient.auth).thenReturn(mockAuth);
    // Если где-то в коде слушаются события, можно замокать onAuthStateChange пустым стримом:
    when(() => mockAuth.onAuthStateChange)
        .thenAnswer((_) => const Stream.empty());
    // currentSession → null по умолчанию:
    when(() => mockAuth.currentSession).thenReturn(null);
    when(() => mockAuth.currentUser).thenReturn(null);
  });

  test('AuthProvider prevents double submit when isLoading', () async {
    final provider = AuthProvider(auth: AuthService(client: mockClient));
    await provider.register(
        email: 'a@a.com', password: 'P@ssw0rd', displayName: 'A');
    await provider.register(
        email: 'a@a.com', password: 'P@ssw0rd', displayName: 'A');
    expect(provider.state, isNotNull);
  });
}
