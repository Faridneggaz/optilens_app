import 'stock_entry.dart';

class StockEntryResponse {
  final List<StockEntry> stockEntries;
  final bool isSearch;

  StockEntryResponse({required this.stockEntries, this.isSearch = false});

  static StockEntryResponse fromJson(Map<String, dynamic> json) {
    final message = json["message"];
    List<StockEntry> entries = [];
    bool isSearch = false;

    if (message is List) {
      entries = message.map((e) => StockEntry.fromJson(e)).toList();
    } else if (message is Map && message.containsKey("stock_entries")) {
      entries = (message["stock_entries"] as List)
          .map((e) => StockEntry.fromJson(e))
          .toList();
      isSearch = message["is_search"] ?? false;
    }

    return StockEntryResponse(
      stockEntries: entries,
      isSearch: isSearch,
    );
  }
}
