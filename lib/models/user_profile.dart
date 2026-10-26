import 'package:flutter/foundation.dart';

import 'gender.dart';

@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.role,
    this.gender,
    this.profilePictureUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    String text(String key) => (json[key] as String?)?.trim() ?? '';

    return UserProfile(
      id: text('id'),
      firstName: text('firstName'),
      lastName: text('lastName'),
      username: text('username'),
      email: text('email'),
      role: text('role'),
      gender: Gender.fromApi(json['gender']),
      profilePictureUrl: json['profilePictureUrl'] as String?,
    );
  }

  final String id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String role;
  final Gender? gender;
  final String? profilePictureUrl;

  String get fullName => [firstName, lastName]
      .where((part) => part.isNotEmpty)
      .join(' ');
}
