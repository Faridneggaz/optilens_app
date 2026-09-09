import '../../core/network/api_client.dart';
import '../../domain/response/stock_entry_response.dart';

class StockEntryRepository {
  StockEntryRepository(this._client);

  final ApiClient _client;

  Future<StockEntryResponse> fetchLastStockEntries({
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
      'get_last_stock_entries',
      query: query,
      attachToken: false,
    );
    _client.unwrap(decoded);
    return StockEntryResponse.fromJson(decoded);
  }
}
