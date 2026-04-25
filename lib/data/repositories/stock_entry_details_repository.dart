import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';
import '../../domain/response/stock_entry_details_response.dart';
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
    final url = Uri.parse('$_baseUrl$_fetchEndpoint?name=$name&token=$token');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['error'] != null) {
          throw RepositoryException('API error: ${decoded['error']}');
        }
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
    final url = Uri.parse('$_baseUrl$_manageEndpoint?token=$token');
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
        final resData = data['message'] ?? data;
        if (resData['message'] == 'Success') {
          return {
            'message': 'Success',
            'detail': resData['detail'] ?? 'Operation completed successfully',
          };
        } else if (resData['error'] != null) {
          throw RepositoryException(resData['error'].toString());
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
