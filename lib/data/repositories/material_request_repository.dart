import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';
import '../../domain/response/material_request_response.dart';
import 'repository_exception.dart';

class MaterialRequestRepository {
  static const String _baseUrl        = ApiConfig.apiMethodPath;
  static const String _getEndpoint    = 'mobile_app.api.get_material_requests';
  static const String _getDetailEndpoint = 'mobile_app.api.get_material_request_detail';
  static const String _createEndpoint = 'mobile_app.api.create_material_request';
  static const String _manageEndpoint = 'mobile_app.api.manage_material_request';
  static const String _searchEndpoint = 'mobile_app.api.search_items';
  static const String _warehousesEndpoint = 'mobile_app.api.get_warehouses';

  Future<MaterialRequestResponse> fetchMaterialRequests({
    required String token,
    int     limit  = 20,
    int     offset = 0,
    String? searchText,
    String? status,
  }) async {
    String urlStr =
        '$_baseUrl$_getEndpoint?token=$token&limit=$limit&offset=$offset';
    if (searchText != null && searchText.isNotEmpty) {
      urlStr += '&search_text=$searchText';
    }
    if (status != null && status != 'All') {
      urlStr += '&status=$status';
    }
    final url = Uri.parse(urlStr);
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return MaterialRequestResponse.fromJson(json.decode(response.body));
      }
      throw RepositoryException('Server error: ${response.statusCode}');
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }

  Future<MaterialRequest> fetchDetail({
    required String token,
    required String name,
  }) async {
    final url = Uri.parse(
      '$_baseUrl$_getDetailEndpoint?token=$token&name=${Uri.encodeComponent(name)}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final msg = body['message'] ?? body;
        if (msg['success'] == true && msg['material_request'] != null) {
          final mrData = msg['material_request'];
          mrData['items'] = msg['items'] ?? [];
          return MaterialRequest.fromJson(Map<String, dynamic>.from(mrData));
        } else if (msg is Map<String, dynamic> && msg.containsKey('name')) {
           return MaterialRequest.fromJson(msg);
        }
        throw RepositoryException('Invalid response format');
      }
      throw RepositoryException('Server error: ${response.statusCode}');
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }

  Future<List<Map<String, String>>> fetchWarehouses({
    required String token,
    required String company,
  }) async {
    final url = Uri.parse(
      '$_baseUrl$_warehousesEndpoint?token=$token&company=${Uri.encodeComponent(company)}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final msg = body['message'] ?? body;
        if (msg['warehouses'] != null) {
          final whList = msg['warehouses'] as List;
          return whList.map<Map<String, String>>((w) => {
            'name': w['name']?.toString() ?? '',
            'warehouse_name': w['warehouse_name']?.toString() ?? '',
            'company': w['company']?.toString() ?? '',
          }).toList();
        }
        return [];
      }
      throw RepositoryException('Server error: ${response.statusCode}');
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> createMaterialRequest({
    required String token,
    required String company,
    required String purpose,
    required String requiredBy,
    required String setWarehouse,
    String? setFromWarehouse,
    required List<Map<String, dynamic>> items,
  }) async {
    final url = Uri.parse('$_baseUrl$_createEndpoint?token=$token');
    try {
      final body = {
        'company':     company,
        'purpose':     purpose,
        'required_by': requiredBy,
        'set_warehouse': setWarehouse,
        'items':       items,
        'token':       token,
      };
      if (setFromWarehouse != null && setFromWarehouse.isNotEmpty) {
        body['set_from_warehouse'] = setFromWarehouse;
      }
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data['message'] ?? data);
      }
      throw RepositoryException('Server error: ${response.statusCode}');
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> manageMaterialRequest({
    required String token,
    required String name,
    required String action,
  }) async {
    final url = Uri.parse('$_baseUrl$_manageEndpoint?token=$token');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name':   name,
          'action': action,
          'token':  token,
        }),
      );
      if (response.statusCode == 200) {
        final data    = jsonDecode(response.body);
        final resData = data['message'] ?? data;
        if (resData['message'] == 'Success') {
          return {
            'message': 'Success',
            'detail':  resData['detail'] ?? 'Operation completed',
            'status':  resData['status'] ?? '',
          };
        } else if (resData['error'] != null) {
          throw RepositoryException(resData['error'].toString());
        }
        throw const RepositoryException('Unknown response format');
      }
      throw RepositoryException('Server error: ${response.statusCode}');
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }

  Future<List<Map<String, String>>> searchItems({
    required String token,
    required String searchText,
  }) async {
    final url = Uri.parse(
        '$_baseUrl$_searchEndpoint?token=$token&search_text=$searchText');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List itemsList;
        if (decoded is Map && decoded['message'] != null) {
          itemsList = decoded['message'] as List;
        } else if (decoded is List) {
          itemsList = decoded;
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
      throw RepositoryException('Server error: ${response.statusCode}');
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }
}
