// ignore_for_file: annotate_overrides
import '../../core/network/api_client.dart';
import '../../domain/entities/stock_entry_response.dart';
import '../../domain/entities/stock_summary.dart';
import '../../domain/failures/failures.dart';
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

  Future<StockSummaryResponse> fetchStockSummary({
    required String token,
    int limit = 20,
    int offset = 0,
    String? searchText,
    String? warehouse,
    String? company,
    bool onlyInStock = true,
    bool onlyNegative = false,
    bool includeLowStockOnly = false,
  }) async {
    final query = <String, String>{
      'token': token,
      'limit': '$limit',
      'offset': '$offset',
      'only_in_stock': onlyInStock ? '1' : '0',
      'only_negative': onlyNegative ? '1' : '0',
      'include_low_stock_only': includeLowStockOnly ? '1' : '0',
      'qty_filter': onlyNegative
          ? 'negative'
          : (onlyInStock ? 'positive' : 'all'),
    };
    if (searchText != null && searchText.isNotEmpty) {
      query['search_text'] = searchText;
    }
    if (warehouse != null && warehouse.isNotEmpty && warehouse != 'All') {
      query['warehouse'] = warehouse;
    }
    if (company != null && company.isNotEmpty) {
      query['company'] = company;
    }
    final decoded = await _client.getMobile(
      'get_stock_summary',
      query: query,
      attachToken: false,
    );
    final msg = _client.unwrap(decoded);
    if (msg is Map) {
      final map = Map<String, dynamic>.from(msg);
      final err = map['error']?.toString();
      if (err != null && err.isNotEmpty && map['success'] != true) {
        throw RepositoryException(err);
      }
      return StockSummaryResponseMapper.fromJson(map);
    }
    if (decoded['message'] is Map || decoded.containsKey('items')) {
      return StockSummaryResponseMapper.fromJson(decoded);
    }
    throw const RepositoryException('Invalid stock summary response');
  }
}
