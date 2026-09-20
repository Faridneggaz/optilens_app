import '../entities/stock_entry_response.dart';
import '../entities/stock_summary.dart';

abstract class StockEntryRepository {
  Future<StockEntryResponse> fetchLastStockEntries({
    required String token,
    int limit = 20,
    int offset = 0,
    String? searchText,
    String? status,
  });

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
  });
}
