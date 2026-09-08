import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';
import '../../domain/response/stock_entry_details_response.dart';
import 'employee_api.dart';
import 'repository_exception.dart';

class StockEntryDetailsRepository {
  static const String _baseUrl = ApiConfig.apiMethodPath;
  static const String _fetchEndpoint =
      'mobile_app.api.get_stock_entry_details_by_name';
  static const String _manageEndpoint = 'mobile_app.api.manage_stock_entry';
  static const String _searchEndpoint = 'mobile_app.api.search_items';

  Future<StockEntryDetailsResponse> fetchDetails({
    required String name,
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl$_fetchEndpoint?name=${Uri.encodeComponent(name)}&token=${Uri.encodeComponent(token)}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        EmployeeApi.unwrap(decoded);
        return StockEntryDetailsResponse.fromJson(decoded);
      }
      throw RepositoryException('Server error: ${response.statusCode}');
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> approveStockEntry({
    required String name,
    required String token,
    required List<Map<String, dynamic>> items,
    required String action,
  }) async {
    final url = Uri.parse('$_baseUrl$_manageEndpoint?token=${Uri.encodeComponent(token)}');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'items': items,
          'action': action,
          'token': token,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final resData = EmployeeApi.unwrap(data);
        if (resData is Map && resData['message'] == 'Success') {
          return {
            'message': 'Success',
            'detail': resData['detail'] ?? 'Operation completed successfully',
          };
        }
        throw const RepositoryException('Unknown response format');
      }
      throw RepositoryException(
          'Server error: ${response.statusCode} – ${response.body}');
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
        '$_baseUrl$_searchEndpoint?token=${Uri.encodeComponent(token)}&search_text=${Uri.encodeComponent(searchText)}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final message = EmployeeApi.unwrap(decoded);
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
      throw RepositoryException('Server error: ${response.statusCode}');
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }
}
