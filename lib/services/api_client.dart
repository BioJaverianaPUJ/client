import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    String baseUrl = ApiConfig.baseUrl,
    this.timeout = ApiConfig.timeout,
  })  : _http = httpClient ?? http.Client(),
        _baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;

  final http.Client _http;
  final String _baseUrl;
  final Duration timeout;

  String? token;
  void Function()? onUnauthorized;

  Future<Map<String, dynamic>> get(String path) =>
      _send('GET', path, authenticated: true);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) =>
      _send('POST', path, body: body, authenticated: authenticated);

  Future<Map<String, dynamic>> patch(
    String path, {
    required Map<String, dynamic> body,
  }) =>
      _send('PATCH', path, body: body, authenticated: true);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required bool authenticated,
  }) async {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'))
      ..headers['Accept'] = 'application/json';

    final currentToken = token;
    if (authenticated && currentToken != null) {
      request.headers['Authorization'] = 'Bearer $currentToken';
    }

    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      final streamed = await _http.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed).timeout(timeout);
    } on TimeoutException {
      throw const ApiException(ApiErrorKind.timeout);
    } on http.ClientException {
      throw const ApiException(ApiErrorKind.network);
    }

    final text = utf8.decode(response.bodyBytes, allowMalformed: true);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = ApiException.fromResponse(response.statusCode, text);
      if (authenticated &&
          currentToken != null &&
          error.kind == ApiErrorKind.unauthorized) {
        onUnauthorized?.call();
      }
      throw error;
    }

    if (text.trim().isEmpty) {
      return const {};
    }

    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      throw ApiException(ApiErrorKind.server, statusCode: response.statusCode);
    }

    throw ApiException(ApiErrorKind.server, statusCode: response.statusCode);
  }

  void close() => _http.close();
}
