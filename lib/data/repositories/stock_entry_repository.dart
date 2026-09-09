// ignore_for_file: annotate_overrides
import '../../core/network/api_client.dart';
import '../../domain/entities/stock_entry_response.dart';
import '../../domain/repositories/stock_entry_repository.dart';
import '../mappers/json_mappers.dart';

class StockEntryRepositoryImpl implements StockEntryRepository {
  StockEntryRepositoryImpl(this._client);

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
    return StockEntryResponseMapper.fromJson(decoded);
  }
}
