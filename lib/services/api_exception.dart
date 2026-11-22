import 'dart:convert';

enum ApiErrorKind {
  network,
  timeout,
  invalidCredentials,
  unauthorized,
  deactivated,
  forbidden,
  emailTaken,
  usernameTaken,
  validation,
  notFound,
  tooManyRequests,
  server,
  unknown,
}

class ApiException implements Exception {
  const ApiException(
    this.kind, {
    this.statusCode,
    this.code,
    this.serverMessage,
    this.details = const {},
  });

  factory ApiException.fromResponse(int statusCode, String body) {
    String? code;
    String? serverMessage;
    Map<String, dynamic> details = const {};

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        code = decoded['code'] as String?;
        serverMessage = decoded['message'] as String?;
        // ErrorResponse: { status, code, message, path, timestamp, details }.
        if (decoded['details'] is Map<String, dynamic>) {
          details = decoded['details'] as Map<String, dynamic>;
        }
      }
    } on FormatException {
      code = null;
    }

    final kind = switch (code) {
      'INVALID_CREDENTIALS' => ApiErrorKind.invalidCredentials,
      'USER_DEACTIVATED' => ApiErrorKind.deactivated,
      'EMAIL_ALREADY_LINKED' => ApiErrorKind.emailTaken,
      'USERNAME_ALREADY_EXISTS' => ApiErrorKind.usernameTaken,
      'VALIDATION_ERROR' => ApiErrorKind.validation,
      'USERNAME_CHANGE_COOLDOWN' => ApiErrorKind.tooManyRequests,
      _ => switch (statusCode) {
        400 => ApiErrorKind.validation,
        401 => ApiErrorKind.unauthorized,
        403 => ApiErrorKind.forbidden,
        404 => ApiErrorKind.notFound,
        409 => ApiErrorKind.validation,
        429 => ApiErrorKind.tooManyRequests,
        >= 500 => ApiErrorKind.server,
        _ => ApiErrorKind.unknown,
      },
    };

    return ApiException(
      kind,
      statusCode: statusCode,
      code: code,
      serverMessage: serverMessage,
      details: details,
    );
  }

  final ApiErrorKind kind;
  final int? statusCode;
  final String? code;
  final String? serverMessage;
  final Map<String, dynamic> details;

  /// Fin de una suspensión temporal (details.expiresAt de USER_DEACTIVATED).
  DateTime? get banExpiresAt {
    final value = details['expiresAt'];
    return value is String ? DateTime.tryParse(value)?.toLocal() : null;
  }

  String get _suspension {
    final until = banExpiresAt;
    if (details['banType'] == 'permanent' || until == null) {
      return 'Tu cuenta está suspendida de forma indefinida. Si crees que es un error, comunícate con los administradores de BioJaveriana.';
    }
    String two(int v) => v.toString().padLeft(2, '0');
    final hour = until.hour % 12 == 0 ? 12 : until.hour % 12;
    final when =
        '${two(until.day)}/${two(until.month)}/${until.year} a las $hour:${two(until.minute)} ${until.hour < 12 ? 'a. m.' : 'p. m.'}';
    return 'Tu cuenta está suspendida hasta el $when. Podrás volver a entrar después de esa fecha.';
  }

  String get message => code == 'USERNAME_CHANGE_COOLDOWN'
      ? 'Solo puedes cambiar tu nombre de usuario una vez cada dos semanas.'
      : switch (kind) {
          ApiErrorKind.network => 'No hay conexión con el servidor. Revisa tu internet e intenta de nuevo.',
          ApiErrorKind.timeout =>
            'El servidor tardó demasiado en responder. Intenta de nuevo.',
          ApiErrorKind.invalidCredentials => 'Correo o contraseña incorrectos.',
          ApiErrorKind.unauthorized =>
            'Tu sesión expiró. Inicia sesión de nuevo.',
          ApiErrorKind.deactivated => _suspension,
          ApiErrorKind.forbidden =>
            'No tienes permiso para realizar esta acción.',
          ApiErrorKind.emailTaken => 'Ya existe una cuenta con este correo.',
          ApiErrorKind.usernameTaken => 'Ese nombre de usuario ya está en uso.',
          ApiErrorKind.validation => _validationMessage(),
          ApiErrorKind.notFound => 'No encontramos lo que buscabas.',
          ApiErrorKind.tooManyRequests =>
            'Demasiados intentos. Espera un momento e intenta de nuevo.',
          ApiErrorKind.server =>
            'El servidor tuvo un problema. Intenta de nuevo en unos minutos.',
          ApiErrorKind.unknown =>
            'Ocurrió un error inesperado. Intenta de nuevo.',
        };

  String _validationMessage() {
    final detail = serverMessage ?? '';
    if (detail.contains('password')) {
      return 'La contraseña debe tener entre 8 y 72 caracteres.';
    }
    if (detail.contains('email')) {
      return 'Revisa que el correo esté bien escrito.';
    }
    if (detail.contains('username')) {
      return 'El nombre de usuario debe tener entre 3 y 25 caracteres.';
    }
    return 'Revisa los datos ingresados e intenta de nuevo.';
  }

  @override
  String toString() => 'ApiException($kind, $statusCode, $code)';
}
