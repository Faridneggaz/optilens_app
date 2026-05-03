import 'stock_entry_details.dart';
import 'stock_entry_item.dart';

class StockEntryDetailsResponse {
  final StockEntryDetails stockEntry;
  final List<StockEntryItem> items;

  StockEntryDetailsResponse({required this.stockEntry, required this.items});

  static StockEntryDetailsResponse fromJson(Map<String, dynamic> json) {
    return StockEntryDetailsResponse(
      stockEntry: StockEntryDetails.fromJson(json["message"]["stockEntry"]),
      items: (json["message"]["items"] as List)
          .map((i) => StockEntryItem.fromJson(i))
          .toList(),
    );
  }
}
