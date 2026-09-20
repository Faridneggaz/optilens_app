class StockSummaryTotals {
  const StockSummaryTotals({
    required this.totalItems,
    required this.totalQty,
    required this.lowStockCount,
  });

  final int totalItems;
  final double totalQty;
  final int lowStockCount;
}

class StockSummaryItem {
  const StockSummaryItem({
    required this.itemCode,
    required this.itemName,
    required this.warehouse,
    required this.qty,
    required this.uom,
    required this.isLowStock,
    required this.reorderLevel,
  });

  final String itemCode;
  final String itemName;
  final String warehouse;
  final double qty;
  final String uom;
  final bool isLowStock;
  final double reorderLevel;
}

class StockSummaryResponse {
  const StockSummaryResponse({
    required this.warehouse,
    required this.company,
    required this.summary,
    required this.items,
    this.isSearch = false,
    this.limit = 20,
    this.offset = 0,
    this.hasMore = false,
  });

  final String warehouse;
  final String company;
  final StockSummaryTotals summary;
  final List<StockSummaryItem> items;
  final bool isSearch;
  final int limit;
  final int offset;
  final bool hasMore;
}
