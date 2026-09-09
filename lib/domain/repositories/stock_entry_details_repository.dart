import '../entities/stock_entry_details_response.dart';

abstract class StockEntryDetailsRepository {
  Future<StockEntryDetailsResponse> fetchDetails({
    required String name,
    required String token,
  });

  Future<Map<String, dynamic>> approveStockEntry({
    required String name,
    required String token,
    required List<Map<String, dynamic>> items,
    required String action,
  });

  Future<List<Map<String, String>>> searchItems({
    required String token,
    required String searchText,
  });
}
