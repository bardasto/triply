// lib/presentation/providers/auth_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/services/auth_service.dart';
import '../../data/models/user_model.dart';
import '../../core/config/app_config.dart';

enum AuthViewState { initial, loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  // DI: позволяет подменять сервис в тестах и не трогать Supabase.instance
  final AuthService _auth;

  // ЕДИНСТВЕННЫЙ безымянный конструктор:
  // 1) инициализирует final _auth
  // 2) сразу запускает _bootstrap
  AuthProvider({AuthService? auth}) : _auth = auth ?? AuthService() {
    _bootstrap();
  }

  AuthViewState _state = AuthViewState.initial;
  UserModel? _user;
  String? _error;

  // Поле‑ошибки для подсветки конкретных инпутов
  String? emailFieldError;
  String? passwordFieldError;

  AuthViewState get state => _state;
  bool get isLoading => _state == AuthViewState.loading;
  bool get isAuthenticated => _state == AuthViewState.authenticated;
  UserModel? get user => _user;
  String? get error => _error;

  StreamSubscription<AuthSnapshot>? _sub;

  Future<void> _bootstrap() async {
    _sub?.cancel();
    _sub = _auth.authStateChanges.listen((snap) {
      final session = snap.session;
      if (kDebugMode) debugPrint('Auth event: ${snap.event}');
      if (session != null) {
        _user = UserModel.fromSupabaseUser(session.user);
        _state = AuthViewState.authenticated;
      } else {
        _user = null;
        _state = AuthViewState.unauthenticated;
      }
      notifyListeners();
    });

    final session = _auth.currentSession;
    if (session != null) {
      _user = UserModel.fromSupabaseUser(session.user);
      _state = AuthViewState.authenticated;
    } else {
      _state = AuthViewState.unauthenticated;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // Нормализация общего текста ошибки (для SnackBar)
  String _toErrorMessage(Object e) {
    final raw = e.toString().replaceFirst('Exception: ', '').trim();
    if (raw.isEmpty) return 'Something went wrong. Please try again.';
    return raw;
  }

  void _setLoading() {
    _error = null;
    emailFieldError = null;
    passwordFieldError = null;
    _state = AuthViewState.loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Очистка полевых ошибок при вводе
  void clearEmailError() {
    if (emailFieldError != null) {
      emailFieldError = null;
      notifyListeners();
    }
  }

  void clearPasswordError() {
    if (passwordFieldError != null) {
      passwordFieldError = null;
      notifyListeners();
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (isLoading) return;
    _setLoading();
    try {
      final res = await _auth.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (res.session != null && res.user != null) {
        _user = UserModel.fromSupabaseUser(res.user!);
        _error = null;
        _state = AuthViewState.authenticated;
      } else {
        _user = null;
        _state = AuthViewState.unauthenticated;
        _error = 'Check your inbox to complete sign up or try signing in.';
      }
    } catch (e) {
      final msg = _toErrorMessage(e);
      if (msg.toLowerCase().contains('email') &&
          msg.toLowerCase().contains('already')) {
        emailFieldError = msg;
      }
      _user = null;
      _state = AuthViewState.unauthenticated;
      _error = msg;
    }
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    if (isLoading) return;
    _setLoading();
    try {
      final res = await _auth.signInWithEmail(email: email, password: password);
      if (res.session != null && res.user != null) {
        _user = UserModel.fromSupabaseUser(res.user!);
        _error = null;
        _state = AuthViewState.authenticated;
      } else {
        _user = null;
        _state = AuthViewState.unauthenticated;
        _error = 'Unable to sign in. Please try again.';
      }
    } catch (e) {
      final msg = _toErrorMessage(e);
      if (msg.toLowerCase().contains('invalid')) {
        emailFieldError = 'Invalid email or password';
        passwordFieldError = 'Invalid email or password';
      } else if (msg.toLowerCase().contains('confirm')) {
        emailFieldError = msg;
      }
      _user = null;
      _state = AuthViewState.unauthenticated;
      _error = msg;
    }
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    if (isLoading) return;
    _setLoading();
    try {
      final res = await _auth.signInWithGoogle(
        webClientId: AppConfig.googleClientIdWeb,
        iosClientId: AppConfig.googleClientIdIos,
      );
      if (res.session != null && res.user != null) {
        _user = UserModel.fromSupabaseUser(res.user!);
        _error = null;
        _state = AuthViewState.authenticated;
      } else {
        _user = null;
        _state = AuthViewState.unauthenticated;
        _error = 'Google sign-in failed. Please try again.';
      }
    } catch (e) {
      _user = null;
      _state = AuthViewState.unauthenticated;
      _error = _toErrorMessage(e);
    }
    notifyListeners();
  }

  Future<void> signInWithFacebook() async {
    if (isLoading) return;
    _setLoading();
    try {
      final res = await _auth.signInWithFacebook();
      if (res.session != null && res.user != null) {
        _user = UserModel.fromSupabaseUser(res.user!);
        _error = null;
        _state = AuthViewState.authenticated;
      } else {
        _user = null;
        _state = AuthViewState.unauthenticated;
        _error = 'Facebook sign-in failed. Please try again.';
      }
    } catch (e) {
      _user = null;
      _state = AuthViewState.unauthenticated;
      _error = _toErrorMessage(e);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    if (isLoading) return;
    _setLoading();
    try {
      await _auth.signOut();
      _user = null;
      _error = null;
      emailFieldError = null;
      passwordFieldError = null;
      _state = AuthViewState.unauthenticated;
    } catch (e) {
      _error = _toErrorMessage(e);
      _state = AuthViewState.unauthenticated;
    }
    notifyListeners();
  }
}
