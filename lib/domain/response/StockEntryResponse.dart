import 'StockEntry.dart';

class StockEntryResponse {
  final List<StockEntry> stockEntries;

  StockEntryResponse({required this.stockEntries});

  static StockEntryResponse fromJson(Map<String, dynamic> json) {
    return StockEntryResponse(
      stockEntries: (json["message"] as List)
          .map((e) => StockEntry.fromJson(e))
          .toList(),
    );
  }
}
