// lib/presentation/screens/auth/login/services/login_scroll_service.dart
import 'package:flutter/material.dart';
import '../constants/login_constants.dart';

class LoginScrollService {
  final ScrollController scrollController;

  LoginScrollService(this.scrollController);

  /// Умный автоскроллинг для видимости всех полей
  void smartScrollToField(String fieldType, BuildContext context) {
    Future.delayed(
        Duration(milliseconds: LoginBottomSheetConstants.scrollDelay.toInt()),
        () {
      if (scrollController.hasClients && context.mounted) {
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

        if (keyboardHeight > 0) {
          double scrollRatio = _getScrollRatioForField(fieldType);
          final maxScrollExtent = scrollController.position.maxScrollExtent;
          final targetPosition = maxScrollExtent * scrollRatio;

          scrollController.animateTo(
            targetPosition.clamp(0.0, maxScrollExtent),
            duration: LoginBottomSheetConstants.scrollAnimationDuration,
            curve: LoginBottomSheetConstants.scrollAnimationCurve,
          );
        }
      }
    });
  }

  double _getScrollRatioForField(String fieldType) {
    switch (fieldType) {
      case 'email':
        return LoginBottomSheetConstants.emailScrollRatio;
      case 'password':
        return LoginBottomSheetConstants.passwordScrollRatio;
      default:
        return LoginBottomSheetConstants.buttonScrollRatio;
    }
  }

  void dispose() {
    scrollController.dispose();
  }
}
