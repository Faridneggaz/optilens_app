import '../entities/stock_entry_response.dart';

abstract class StockEntryRepository {
  Future<StockEntryResponse> fetchLastStockEntries({
    required String token,
    int limit = 20,
    int offset = 0,
    String? searchText,
    String? status,
  });
}
