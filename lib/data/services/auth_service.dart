// lib/data/services/auth_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Stream<AuthSnapshot> get authStateChanges =>
      _client.auth.onAuthStateChange.map(
        (e) => AuthSnapshot(event: e.event, session: e.session),
      );

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );

      if (res.user != null) {
        final ids = res.user!.identities;
        if (ids == null || ids.isEmpty) {
          throw Exception('This email is already in use');
        }
      }
      return res;
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return res;
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<AuthResponse> signInWithGoogle({
    required String webClientId,
    String? iosClientId,
  }) async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? (iosClientId ?? webClientId) : null,
        serverClientId: webClientId,
        scopes: const ['email', 'profile'],
      );

      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (account == null) throw Exception('Google sign-in cancelled');

      final googleAuth = await account.authentication;
      if (googleAuth.idToken == null || googleAuth.accessToken == null) {
        throw Exception('Failed to obtain Google tokens');
      }

      final res = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );
      return res;
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<AuthResponse> signInWithFacebook() async {
    try {
      await FacebookAuth.instance.logOut();
      final result = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
      );
      if (result.status != LoginStatus.success || result.accessToken == null) {
        throw Exception('Facebook login failed: ${result.message}');
      }

      final res = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.facebook,
        idToken: result.accessToken!.tokenString,
      );
      return res;
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'triply://reset-password',
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ✅ Метод для обновления пароля
  Future<void> updatePassword({
    required String accessToken,
    required String refreshToken,
    required String newPassword,
  }) async {
    try {
      // ✅ Устанавливаем сессию с токенами из email
      await _client.auth.setSession(accessToken);

      // ✅ Обновляем пароль пользователя
      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        throw Exception('Failed to update password');
      }

      // ✅ Принудительно выходим из системы после обновления пароля
      await signOut();
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Exception _mapAuthException(AuthException e) {
    switch (e.statusCode) {
      case 'user_already_registered':
      case 'user_already_exists':
        return Exception('This email is already in use');
      case 'invalid_credentials':
        return Exception('Invalid email or password');
      case 'email_not_confirmed':
        return Exception('Please confirm your email before signing in');
      case 'too_many_requests':
        return Exception('Too many requests. Please try again later');
      default:
        return Exception(e.message);
    }
  }
}

class AuthSnapshot {
  final AuthChangeEvent event;
  final Session? session;
  AuthSnapshot({required this.event, required this.session});
}
