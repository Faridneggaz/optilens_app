import 'stock_entry_details.dart';
import 'stock_entry_item.dart';

class StockEntryDetailsResponse {
  final StockEntryDetails stockEntry;
  final List<StockEntryItem> items;

  StockEntryDetailsResponse({required this.stockEntry, required this.items});
}
