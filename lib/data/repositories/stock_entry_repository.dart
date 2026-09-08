import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';
import '../../domain/response/stock_entry_response.dart';
import 'employee_api.dart';
import 'repository_exception.dart';

class StockEntryRepository {
  static const String _baseUrl = ApiConfig.apiMethodPath;
  static const String _getLastStockEntries =
      'mobile_app.api.get_last_stock_entries';

  Future<StockEntryResponse> fetchLastStockEntries({
    required String token,
    int limit = 20,
    int offset = 0,
    String? searchText,
    String? status,
  }) async {
    String urlStr = '$_baseUrl$_getLastStockEntries?token=${Uri.encodeComponent(token)}&limit=$limit&offset=$offset';
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
        final decoded = json.decode(response.body);
        EmployeeApi.unwrap(decoded);
        return StockEntryResponse.fromJson(decoded);
      }
      throw RepositoryException('Server error: ${response.statusCode}');
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }
}
