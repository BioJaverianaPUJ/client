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
    this.dataPolicyAcceptedAt,
    this.dataPolicyVersion,
  });

  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final Gender gender;
  final String password;

  /// Momento en que la persona aceptó la política de datos (RF-03).
  final DateTime? dataPolicyAcceptedAt;
  final String? dataPolicyVersion;

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'username': username,
    'email': email,
    'gender': gender.apiValue,
    'password': password,
    // El backend debe guardar estos campos como prueba de la autorización.
    if (dataPolicyAcceptedAt != null)
      'dataPolicyAcceptedAt': dataPolicyAcceptedAt!.toUtc().toIso8601String(),
    if (dataPolicyVersion != null) 'dataPolicyVersion': dataPolicyVersion,
  };
}
