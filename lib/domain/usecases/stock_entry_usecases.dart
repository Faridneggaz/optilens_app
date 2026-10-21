import '../entities/stock_entry_details_response.dart';
import '../entities/stock_entry_response.dart';
import '../entities/stock_summary.dart';
import '../repositories/stock_entry_details_repository.dart';
import '../repositories/stock_entry_repository.dart';
import '../results/action_result.dart';

class StockEntryUseCases {
  StockEntryUseCases(this._list, this._details);
  final StockEntryRepository _list;
  final StockEntryDetailsRepository _details;

  Future<StockEntryResponse> fetchLastStockEntries({
    required String token,
    int limit = 20,
    int offset = 0,
    String? searchText,
    String? status,
  }) =>
      _list.fetchLastStockEntries(
        token: token,
        limit: limit,
        offset: offset,
        searchText: searchText,
        status: status,
      );

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
  }) =>
      _list.fetchStockSummary(
        token: token,
        limit: limit,
        offset: offset,
        searchText: searchText,
        warehouse: warehouse,
        company: company,
        onlyInStock: onlyInStock,
        onlyNegative: onlyNegative,
        includeLowStockOnly: includeLowStockOnly,
      );

  Future<StockEntryDetailsResponse> fetchDetails({
    required String name,
    required String token,
  }) =>
      _details.fetchDetails(name: name, token: token);

  Future<ActionResult> approveStockEntry({
    required String name,
    required String token,
    required List<Map<String, dynamic>> items,
    required String action,
  }) async {
    try {
      final map = await _details.approveStockEntry(
        name: name,
        token: token,
        items: items,
        action: action,
      );
      return ActionResult.fromApiMap(map);
    } catch (e) {
      return ActionResult.fromException(e);
    }
  }

  Future<List<Map<String, String>>> searchItems({
    required String token,
    required String searchText,
  }) =>
      _details.searchItems(token: token, searchText: searchText);
}
