import 'dart:typed_data';

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/attachment_photo.dart';
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
    return Uri.parse(
      '${ApiConfig.apiMethodPath}$method',
    ).replace(queryParameters: q.isEmpty ? null : q);
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
    return getJson(mobileUri(endpoint, query: query, attachToken: attachToken));
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

  Future<Map<String, dynamic>> postMobilePhotos(
    String endpoint, {
    required Map<String, dynamic> body,
    required List<SelectedPhoto> photos,
  }) => postMobileAttachments(endpoint, body: body, photos: photos);

  Future<Map<String, dynamic>> postMobileAttachments(
    String endpoint, {
    required Map<String, dynamic> body,
    required List<SelectedPhoto> photos,
    Uint8List? voiceRecording,
  }) async {
    try {
      final request = http.MultipartRequest('POST', mobileUri(endpoint))
        ..headers['Accept'] = 'application/json'
        ..fields.addAll(
          body.map(
            (key, value) =>
                MapEntry(key, value is String ? value : jsonEncode(value)),
          ),
        );
      for (final photo in photos) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            photo.bytes,
            filename: photo.name,
          ),
        );
      }
      if (voiceRecording != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'voice',
            voiceRecording,
            filename: 'note-vocale.wav',
          ),
        );
      }
      final response = await _http
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 60));
      return _decodeResponse(response);
    } on TimeoutException {
      throw const RepositoryException('Request timeout');
    } on RepositoryException {
      rethrow;
    } catch (error) {
      throw RepositoryException('Network error: $error');
    }
  }

  Future<Uint8List> postMobileImage(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async => (await _postMobileFile(
    endpoint,
    body: body,
    mimeTypes: const {'image/jpeg'},
  )).bytes;

  Future<({Uint8List bytes, String mimeType})> postMobileAudio(
    String endpoint, {
    required Map<String, dynamic> body,
  }) => _postMobileFile(
    endpoint,
    body: body,
    mimeTypes: const {'audio/wav', 'audio/ogg'},
  );

  Future<({Uint8List bytes, String mimeType})> _postMobileFile(
    String endpoint, {
    required Map<String, dynamic> body,
    required Set<String> mimeTypes,
  }) async {
    final http.Response response;
    try {
      response = await _http
          .post(
            mobileUri(endpoint),
            headers: {
              ..._jsonHeaders,
              'Accept': '${mimeTypes.join(', ')}, application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const RepositoryException('Request timeout');
    } on http.ClientException catch (error) {
      throw RepositoryException('Network error: $error');
    }
    final mimeType = response.headers['content-type']?.split(';').first.trim();
    if (response.statusCode == 200 &&
        mimeType != null &&
        mimeTypes.contains(mimeType) &&
        response.bodyBytes.isNotEmpty) {
      return (bytes: response.bodyBytes, mimeType: mimeType);
    }
    unwrap(_decodeResponse(response));
    throw RepositoryException(
      'Invalid ${mimeTypes.first.split('/').first} response',
    );
  }

  Future<Map<String, dynamic>> getJson(
    Uri uri, {
    Map<String, String>? headers,
  }) => _send('GET', uri, extraHeaders: headers);

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
      extraHeaders: {'Authorization': 'token ${ApiConfig.erpApiToken}'},
      allowCreated: true,
    );
    if (json.containsKey('exc') || json['exception'] != null) {
      throw RepositoryException(
        json['exception']?.toString() ?? 'ERP request failed',
      );
    }
  }

  /// GET `frappe.client.get_list` with the employee SID cookie (same session as mobile APIs).
  Future<List<dynamic>> getList({
    required String doctype,
    required String token,
    List<String> fields = const ['name'],
    Object? filters,
    Object? orFilters,
    int limitPageLength = 50,
    String? orderBy,
  }) async {
    final query = <String, String>{
      'doctype': doctype,
      'fields': jsonEncode(fields),
      'limit_page_length': '$limitPageLength',
    };
    if (filters != null) query['filters'] = jsonEncode(filters);
    if (orFilters != null) query['or_filters'] = jsonEncode(orFilters);
    if (orderBy != null && orderBy.trim().isNotEmpty) {
      query['order_by'] = orderBy.trim();
    }
    final uri = methodUri('frappe.client.get_list', query: query);
    final decoded = await getJson(uri, headers: {'Cookie': 'sid=$token'});
    final msg = unwrap(decoded);
    if (msg is List) return msg;
    if (msg is Map && msg['data'] is List) return msg['data'] as List;
    if (decoded['message'] is List) return decoded['message'] as List;
    return const [];
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

      return _decodeResponse(response, allowCreated: allowCreated);
    } on TimeoutException {
      throw const RepositoryException('Request timeout');
    } on RepositoryException {
      rethrow;
    } catch (e) {
      throw RepositoryException('Network error: $e');
    }
  }

  Map<String, dynamic> _decodeResponse(
    http.Response response, {
    bool allowCreated = false,
  }) {
    final ok =
        response.statusCode == 200 ||
        (allowCreated && response.statusCode == 201);
    if (response.body.isEmpty) {
      if (!ok) {
        throw RepositoryException('Server error: ${response.statusCode}');
      }
      return {};
    }
    Map<String, dynamic>? decodedMap;
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        decodedMap = decoded;
      } else if (decoded is Map) {
        decodedMap = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      decodedMap = null;
    }
    if (!ok) {
      final fromFrappe = decodedMap == null
          ? null
          : FrappeMessage.exceptionMessage(decodedMap) ??
                FrappeMessage.parseServerMessages(
                  decodedMap['_server_messages'],
                ) ??
                decodedMap['message']?.toString();
      throw RepositoryException(
        (fromFrappe != null && fromFrappe.trim().isNotEmpty)
            ? fromFrappe
            : 'Server error: ${response.statusCode}',
      );
    }
    if (decodedMap != null) {
      final fault = FrappeMessage.exceptionMessage(decodedMap);
      if (fault != null && fault.trim().isNotEmpty) {
        throw RepositoryException(fault);
      }
      return decodedMap;
    }
    throw const RepositoryException('Invalid JSON response');
  }
}
