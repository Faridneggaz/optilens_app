import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/failures/failures.dart';
import 'frappe_message.dart';
import '../../utils/api_config.dart';

/// Shared HTTP client for Frappe `/api/method` and optional ERP `/api/resource`.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    this.tokenProvider,
    this.timeout = const Duration(seconds: 15),
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final String? Function()? tokenProvider;
  final Duration timeout;

  static const _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  String get currentToken => tokenProvider?.call() ?? '';

  String get _token => currentToken;

  /// Unwraps Frappe `{ message: ... }` and maps session / access errors.
  dynamic unwrap(Map<String, dynamic> decoded) => FrappeMessage.unwrap(decoded);

  Uri methodUri(
    String method, {
    Map<String, String>? query,
    bool attachToken = false,
  }) {
    final q = <String, String>{...?query};
    if (attachToken) {
      q['token'] = _token;
    }
    return Uri.parse('${ApiConfig.apiMethodPath}$method').replace(
      queryParameters: q.isEmpty ? null : q,
    );
  }

  Uri mobileUri(
    String endpoint, {
    Map<String, String>? query,
    bool attachToken = false,
  }) {
    return methodUri(
      'mobile_app.api.$endpoint',
      query: query,
      attachToken: attachToken,
    );
  }

  Future<Map<String, dynamic>> getMobile(
    String endpoint, {
    Map<String, String>? query,
    bool attachToken = true,
  }) {
    return getJson(
      mobileUri(endpoint, query: query, attachToken: attachToken),
    );
  }

  Future<Map<String, dynamic>> postMobile(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool attachToken = true,
  }) {
    return postJson(
      mobileUri(endpoint, query: query, attachToken: attachToken),
      body: body,
    );
  }

  Future<Map<String, dynamic>> getJson(Uri uri) => _send('GET', uri);

  Future<Map<String, dynamic>> postJson(Uri uri, {Object? body}) =>
      _send('POST', uri, body: body);

  /// POST to Frappe Resource API (`/api/resource/...`). Requires [ApiConfig.erpApiToken].
  Future<void> postErpResource(
    String resource,
    Map<String, dynamic> body,
  ) async {
    if (ApiConfig.erpApiToken.isEmpty) {
      throw const RepositoryException('ERP API token is not configured');
    }
    final uri = Uri.parse('${ApiConfig.erpBaseUrl}/api/resource/$resource');
    final json = await _send(
      'POST',
      uri,
      body: body,
      extraHeaders: {
        'Authorization': 'token ${ApiConfig.erpApiToken}',
      },
      allowCreated: true,
    );
    if (json.containsKey('exc') || json['exception'] != null) {
      throw RepositoryException(
        json['exception']?.toString() ?? 'ERP request failed',
      );
    }
  }

  Future<Map<String, dynamic>> _send(
    String verb,
    Uri uri, {
    Object? body,
    Map<String, String>? extraHeaders,
    bool allowCreated = false,
  }) async {
    try {
      final headers = {..._jsonHeaders, ...?extraHeaders};
      final response = verb == 'GET'
          ? await _http.get(uri, headers: headers).timeout(timeout)
          : await _http
              .post(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(timeout);

      final ok = response.statusCode == 200 ||
          (allowCreated && response.statusCode == 201);
      if (!ok) {
        throw RepositoryException('Server error: ${response.statusCode}');
      }
      if (response.body.isEmpty) return {};
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      throw const RepositoryException('Invalid JSON response');
    } on TimeoutException {
      throw const RepositoryException('Request timeout');
    } on RepositoryException {
      rethrow;
    } catch (e) {
      throw RepositoryException('Network error: $e');
    }
  }
}
