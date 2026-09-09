import 'stock_entry.dart';

class StockEntryResponse {
  final List<StockEntry> stockEntries;
  final bool isSearch;

  StockEntryResponse({required this.stockEntries, this.isSearch = false});
}
