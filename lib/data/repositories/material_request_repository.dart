// ignore_for_file: annotate_overrides
import '../../core/network/api_client.dart';
import '../../domain/entities/material_request_response.dart';
import '../../domain/failures/failures.dart';
import '../../domain/repositories/material_request_repository.dart';
import '../mappers/json_mappers.dart';

class MaterialRequestRepositoryImpl implements MaterialRequestRepository {
  MaterialRequestRepositoryImpl(this._client);

  final ApiClient _client;

  Future<MaterialRequestResponse> fetchMaterialRequests({
    required String token,
    int limit = 20,
    int offset = 0,
    String? searchText,
    String? status,
  }) async {
    final query = <String, String>{
      'token': token,
      'limit': '$limit',
      'offset': '$offset',
      'order_by': 'modified desc',
    };
    if (searchText != null && searchText.isNotEmpty) {
      query['search_text'] = searchText;
    }
    if (status != null && status != 'All') {
      query['status'] = status;
    }
    final decoded = await _client.getMobile(
      'get_material_requests',
      query: query,
      attachToken: false,
    );
    _client.unwrap(decoded);
    return MaterialRequestResponseMapper.fromJson(decoded);
  }

  Future<MaterialRequest> fetchDetail({
    required String token,
    required String name,
  }) async {
    final body = await _client.getMobile(
      'get_material_request_detail',
      query: {'token': token, 'name': name},
      attachToken: false,
    );
    final msg = _client.unwrap(body);
    if (msg is Map &&
        msg['success'] == true &&
        msg['material_request'] != null) {
      final mrData = Map<String, dynamic>.from(msg['material_request'] as Map);
      mrData['items'] = msg['items'] ?? [];
      return MaterialRequestMapper.fromJson(mrData);
    } else if (msg is Map && msg.containsKey('name')) {
      return MaterialRequestMapper.fromJson(Map<String, dynamic>.from(msg));
    }
    throw const RepositoryException('Invalid response format');
  }

  Future<List<Map<String, String>>> fetchWarehouses({
    required String token,
    required String company,
  }) async {
    final body = await _client.getMobile(
      'get_warehouses',
      query: {'token': token, 'company': company},
      attachToken: false,
    );
    final msg = _client.unwrap(body);
    if (msg is Map && msg['warehouses'] != null) {
      final whList = msg['warehouses'] as List;
      return whList
          .map<Map<String, String>>((w) => {
                'name': w['name']?.toString() ?? '',
                'warehouse_name': w['warehouse_name']?.toString() ?? '',
                'company': w['company']?.toString() ?? '',
              })
          .toList();
    }
    return [];
  }

  Future<List<String>> fetchCompanies({required String token}) async {
    final body = await _client.getMobile(
      'get_companies',
      query: {'token': token},
      attachToken: false,
    );
    final msg = _client.unwrap(body);
    if (msg is Map && msg['companies'] != null) {
      return (msg['companies'] as List)
          .map((c) => (c['name'] ?? c['company_name'] ?? '').toString())
          .where((name) => name.isNotEmpty)
          .toList();
    }
    return [];
  }

  Future<List<String>> fetchPriceLists({required String token}) async {
    final body = await _client.getMobile(
      'get_price_lists',
      query: {'token': token},
      attachToken: false,
    );
    final msg = _client.unwrap(body);
    if (msg is Map && msg['price_lists'] != null) {
      return (msg['price_lists'] as List)
          .map((p) => (p['name'] ?? '').toString())
          .where((name) => name.isNotEmpty)
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createMaterialRequest({
    required String token,
    required String company,
    required String purpose,
    required String requiredBy,
    String? setWarehouse,
    String? setFromWarehouse,
    String? priceList,
    required List<Map<String, dynamic>> items,
  }) async {
    final body = <String, dynamic>{
      'company': company,
      'purpose': purpose,
      'required_by': requiredBy,
      'items': items,
      'token': token,
    };
    if (setWarehouse != null && setWarehouse.isNotEmpty) {
      body['set_warehouse'] = setWarehouse;
    }
    if (setFromWarehouse != null && setFromWarehouse.isNotEmpty) {
      body['set_from_warehouse'] = setFromWarehouse;
    }
    if (priceList != null && priceList.isNotEmpty) {
      body['price_list'] = priceList;
    }
    final data = await _client.postMobile(
      'create_material_request',
      query: {'token': token},
      body: body,
      attachToken: false,
    );
    final msg = _client.unwrap(data);
    if (msg is String && msg.trim().isNotEmpty) {
      return {'success': true, 'name': msg.trim()};
    }
    if (msg is Map) {
      return Map<String, dynamic>.from(msg);
    }
    throw const RepositoryException('Invalid create material request response');
  }

  Future<Map<String, dynamic>> manageMaterialRequest({
    required String token,
    required String name,
    required String action,
  }) async {
    final data = await _client.postMobile(
      'manage_material_request',
      query: {'token': token},
      body: {'name': name, 'action': action, 'token': token},
      attachToken: false,
    );
    final resData = _client.unwrap(data);
    if (resData is String) {
      final text = resData.trim();
      if (_looksLikeManageSuccess(text, action)) {
        return {'message': 'Success', 'detail': text};
      }
      throw RepositoryException(text.isEmpty ? 'Operation failed' : text);
    }
    if (resData is Map) {
      final map = Map<String, dynamic>.from(resData);
      final nested = map['message'];
      final err = map['error']?.toString();
      final ok = map['message'] == 'Success' ||
          map['success'] == true ||
          map['success'] == 1 ||
          map['status'] == 'success' ||
          (nested is String && _looksLikeManageSuccess(nested, action)) ||
          (nested is Map &&
              (nested['success'] == true || nested['message'] == 'Success'));
      if (err != null && err.isNotEmpty && err != 'null' && !ok) {
        throw RepositoryException(err);
      }
      if (ok) {
        return {
          'message': 'Success',
          'detail': map['detail'] ??
              (nested is String
                  ? nested
                  : (nested is Map ? nested['detail'] : null)) ??
              'Operation completed',
          'status': map['status'] ?? '',
        };
      }
      if (nested is String && nested.trim().isNotEmpty) {
        throw RepositoryException(nested);
      }
    }
    throw const RepositoryException('Unknown response format');
  }

  bool _looksLikeManageSuccess(String text, String action) {
    final lower = text.toLowerCase();
    if (lower.contains('error') ||
        lower.contains('cannot') ||
        lower.contains('failed') ||
        lower.contains('traceback') ||
        lower.contains('permission')) {
      return false;
    }
    return lower.contains('success') ||
        lower.contains('submitted') ||
        lower.contains('deleted') ||
        lower.contains('cancelled') ||
        lower.contains('canceled') ||
        lower.contains(action.toLowerCase());
  }

  Future<Map<String, dynamic>> createStockEntryFromMR({
    required String token,
    required String name,
    String? purpose,
  }) async {
    // Backend derives stock entry type from the Material Request.
    final body = <String, dynamic>{
      'name': name,
      'token': token,
    };
    final data = await _client.postMobile(
      'create_stock_entry_from_mr',
      query: {'token': token, 'name': name},
      body: body,
      attachToken: false,
    );
    final msg = _client.unwrap(data);
    if (msg is String) {
      final text = msg.trim();
      if (_looksLikeErrorText(text)) {
        throw RepositoryException(text);
      }
      final id = _stockEntryIdFromValue(text);
      return {
        'message': 'Success',
        if (id != null) 'stock_entry_id': id,
        'detail': text,
      };
    }
    if (msg is Map) {
      final map = Map<String, dynamic>.from(msg);
      final err = map['error']?.toString();
      final success = map['success'] == true ||
          map['success'] == 1 ||
          map['message'] == 'Success';
      if (err != null && err.isNotEmpty && err != 'null' && !success) {
        throw RepositoryException(err);
      }
      if (map['success'] == false) {
        throw RepositoryException(
          err ?? map['message']?.toString() ?? 'Failed to create stock entry',
        );
      }
      final id = _stockEntryIdFromPayload(map);
      if (id != null) {
        map['stock_entry_id'] = id;
        map['message'] = 'Success';
        map['success'] = true;
      } else if (!success) {
        throw const RepositoryException('Failed to create stock entry');
      }
      return map;
    }
    throw const RepositoryException('Unknown response format');
  }

  bool _looksLikeErrorText(String text) {
    final lower = text.toLowerCase();
    return lower.contains('error') ||
        lower.contains('cannot') ||
        lower.contains('failed') ||
        lower.contains('traceback');
  }

  String? _stockEntryIdFromPayload(Map<String, dynamic> map) {
    final nested = map['message'];
    final nestedMap = nested is Map ? Map<String, dynamic>.from(nested) : null;
    final candidates = <dynamic>[
      map['stock_entry_id'],
      map['stock_entry_name'],
      if (map['stock_entry'] is String) map['stock_entry'],
      if (map['stock_entry'] is Map) map['stock_entry']['name'],
      nestedMap?['stock_entry_id'],
      if (nestedMap?['stock_entry'] is String) nestedMap?['stock_entry'],
      if (nestedMap?['stock_entry'] is Map) nestedMap?['stock_entry']['name'],
      if (nested is String) nested,
      map['name'],
      nestedMap?['name'],
    ];
    for (final value in candidates) {
      final id = _stockEntryIdFromValue(value);
      if (id != null) return id;
    }
    return null;
  }

  String? _stockEntryIdFromValue(dynamic value) {
    if (value == null) return null;
    final id = value.toString().trim();
    if (id.isEmpty || id == 'Success') return null;
    if (_looksLikeErrorText(id) && !id.toUpperCase().contains('STE')) {
      return null;
    }
    final extracted = RegExp(
      r'(MAT-STE[-A-Z0-9]+|STE[-A-Z0-9]+)',
      caseSensitive: false,
    ).firstMatch(id);
    if (extracted != null) return extracted.group(1);
    final upper = id.toUpperCase();
    if (upper.contains('MAT-MR')) return null;
    if (!id.contains(' ') && upper.startsWith('MAT-')) return id;
    return null;
  }

  Future<List<Map<String, String>>> searchItems({
    required String token,
    required String searchText,
  }) async {
    final decoded = await _client.getMobile(
      'search_items',
      query: {'token': token, 'search_text': searchText},
      attachToken: false,
    );
    final message = _client.unwrap(decoded);
    List itemsList = const [];
    if (message is List) {
      itemsList = message;
    } else if (message is Map) {
      for (final key in ['message', 'items', 'data']) {
        final value = message[key];
        if (value is List) {
          itemsList = value;
          break;
        }
      }
    }
    return itemsList.whereType<Map>().map<Map<String, String>>((raw) {
      final e = Map<String, dynamic>.from(raw);
      final code =
          (e['item_code'] ?? e['name'] ?? e['value'] ?? '').toString().trim();
      final name = (e['item_name'] ?? e['description'] ?? e['item_code'] ?? code)
          .toString()
          .trim();
      return {
        'item_code': code,
        'item_name': name.isEmpty ? code : name,
      };
    }).where((e) => e['item_code']!.isNotEmpty).toList();
  }
}
