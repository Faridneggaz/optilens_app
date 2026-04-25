import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';
import '../../domain/response/stock_entry_response.dart';
import 'repository_exception.dart';

class StockEntryRepository {
  static const String _baseUrl = ApiConfig.apiMethodPath;
  static const String _getLastStockEntries =
      'mobile_app.api.get_last_stock_entries';

  Future<StockEntryResponse> fetchLastStockEntries({
    required String token,
    int limit = 20,
    int offset = 0,
  }) async {
    final url = Uri.parse(
      '$_baseUrl$_getLastStockEntries?token=$token&limit=$limit&offset=$offset',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return StockEntryResponse.fromJson(json.decode(response.body));
      }
      throw RepositoryException('Server error: ${response.statusCode}');
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }
}
