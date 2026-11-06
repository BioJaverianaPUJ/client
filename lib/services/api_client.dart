import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/community.dart';

import '../config/api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    String baseUrl = ApiConfig.baseUrl,
    this.timeout = ApiConfig.timeout,
  }) : _http = httpClient ?? http.Client(),
       _baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl;

  final http.Client _http;
  final String _baseUrl;
  final Duration timeout;

  String? token;
  void Function()? onUnauthorized;
  void Function()? onDeactivated;

  Future<Map<String, dynamic>> delete(String path) =>
      _send('DELETE', path, authenticated: true);

  Future<void> uploadSignedPhoto(
    LocalPhoto photo,
    Map<String, dynamic> signed,
  ) async {
    final url = Uri.parse(signed['url'] as String);
    if (url.scheme != 'https' ||
        signed['method'] != 'PUT' ||
        signed['contentType'] != photo.mimeType) {
      throw const ApiException(ApiErrorKind.server);
    }
    // A presigned storage request must never carry the application's bearer token.
    final request = http.Request('PUT', url)
      ..followRedirects = false
      ..headers['Content-Type'] = photo.mimeType
      ..bodyBytes = photo.bytes;
    try {
      final response = await _http.send(request).timeout(timeout);
      await response.stream.drain<void>().timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const ApiException(ApiErrorKind.server);
      }
    } on TimeoutException {
      throw const ApiException(ApiErrorKind.timeout);
    } on http.ClientException {
      throw const ApiException(ApiErrorKind.network);
    }
  }

  Future<Map<String, dynamic>> uploadProfile(
    LocalPhoto photo,
    String type,
  ) async {
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse(
        '$_baseUrl/users/me/media?type=${Uri.encodeQueryComponent(type)}',
      ),
    );
    final currentToken = token;
    request.headers['Accept'] = 'application/json';
    if (currentToken != null) {
      request.headers['Authorization'] = 'Bearer $currentToken';
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        photo.bytes,
        filename: photo.name,
        contentType: MediaType.parse(photo.mimeType),
      ),
    );
    try {
      final response = await http.Response.fromStream(
        await _http.send(request).timeout(timeout),
      ).timeout(timeout);
      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = ApiException.fromResponse(response.statusCode, body);
        if (token == currentToken) {
          if (error.kind == ApiErrorKind.unauthorized) onUnauthorized?.call();
          if (error.kind == ApiErrorKind.deactivated) onDeactivated?.call();
        }
        throw error;
      }
      return jsonDecode(body) as Map<String, dynamic>;
    } on TimeoutException {
      throw const ApiException(ApiErrorKind.timeout);
    } on http.ClientException {
      throw const ApiException(ApiErrorKind.network);
    } on FormatException {
      throw const ApiException(ApiErrorKind.server);
    }
  }

  Future<Map<String, dynamic>> get(String path) =>
      _send('GET', path, authenticated: true);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) => _send('POST', path, body: body, authenticated: authenticated);

  Future<Map<String, dynamic>> patch(
    String path, {
    required Map<String, dynamic> body,
  }) => _send('PATCH', path, body: body, authenticated: true);

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
          token == currentToken &&
          error.kind == ApiErrorKind.deactivated) {
        onDeactivated?.call();
      }
      if (authenticated &&
          currentToken != null &&
          token == currentToken &&
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
