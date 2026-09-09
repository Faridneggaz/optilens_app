import '../../core/network/api_client.dart';
import '../../domain/response/material_request_response.dart';
import 'repository_exception.dart';

class MaterialRequestRepository {
  MaterialRequestRepository(this._client);

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
    return MaterialRequestResponse.fromJson(decoded);
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
      return MaterialRequest.fromJson(mrData);
    } else if (msg is Map && msg.containsKey('name')) {
      return MaterialRequest.fromJson(Map<String, dynamic>.from(msg));
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
    required String setWarehouse,
    String? setFromWarehouse,
    String? priceList,
    required List<Map<String, dynamic>> items,
  }) async {
    final body = <String, dynamic>{
      'company': company,
      'purpose': purpose,
      'required_by': requiredBy,
      'set_warehouse': setWarehouse,
      'items': items,
      'token': token,
    };
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
    return Map<String, dynamic>.from(msg as Map);
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
    if (resData is Map && resData['message'] == 'Success') {
      return {
        'message': 'Success',
        'detail': resData['detail'] ?? 'Operation completed',
        'status': resData['status'] ?? '',
      };
    }
    throw const RepositoryException('Unknown response format');
  }

  Future<Map<String, dynamic>> createStockEntryFromMR({
    required String token,
    required String name,
  }) async {
    final data = await _client.postMobile(
      'create_stock_entry_from_mr',
      query: {'token': token},
      body: {'name': name, 'token': token},
      attachToken: false,
    );
    final msg = _client.unwrap(data);
    return Map<String, dynamic>.from(msg as Map);
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
    List itemsList;
    if (message is List) {
      itemsList = message;
    } else if (message is Map && message['message'] is List) {
      itemsList = message['message'] as List;
    } else {
      return [];
    }
    return itemsList
        .map<Map<String, String>>((e) => {
              'item_code': e['item_code']?.toString() ?? '',
              'item_name': e['item_name']?.toString() ?? '',
            })
        .toList();
  }
}
