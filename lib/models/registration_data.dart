import 'package:flutter/foundation.dart';

import 'gender.dart';

@immutable
class RegistrationData {
  const RegistrationData({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.gender,
    required this.password,
  });

  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final Gender gender;
  final String password;

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'email': email,
        'gender': gender.apiValue,
        'password': password,
      };
}
