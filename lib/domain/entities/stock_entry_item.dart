class StockEntryItem {
  final String id;
  final int idx;
  final String itemCode;
  final String itemName;
  final String fromWarehouse;
  final String toWarehouse;
  int quantity;

  StockEntryItem({
    required this.id,
    required this.idx,
    required this.itemCode,
    required this.itemName,
    required this.fromWarehouse,
    required this.toWarehouse,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemCode,
      'quantity': quantity,
      'fromWarehouse': fromWarehouse,
      'toWarehouse': toWarehouse,
    };
  }
}
