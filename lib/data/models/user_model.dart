import 'package:supabase_flutter/supabase_flutter.dart';

class UserModel {
  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? emailVerifiedAt;
  final bool isEmailVerified;

  UserModel({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
    this.emailVerifiedAt,
    required this.isEmailVerified,
  });

  // Создание из Supabase User
  factory UserModel.fromSupabaseUser(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      displayName: user.userMetadata?['display_name'] as String?,
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
      createdAt: DateTime.parse(user.createdAt),
      emailVerifiedAt: user.emailConfirmedAt != null
          ? DateTime.parse(user.emailConfirmedAt!)
          : null,
      isEmailVerified: user.emailConfirmedAt != null,
    );
  }

  // Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'is_email_verified': isEmailVerified,
    };
  }

  // Создание копии с изменениями
  UserModel copyWith({
    String? displayName,
    String? avatarUrl,
    DateTime? emailVerifiedAt,
    bool? isEmailVerified,
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName)';
  }
}
