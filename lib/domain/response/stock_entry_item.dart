class StockEntryItem {
  final String id;
  final int idx;
  final String item_name;
  final String from_warehouse;
  final String to_warehouse;
  final int quantity;

  StockEntryItem({
    required this.id,
    required this.idx,
    required this.item_name,
    required this.from_warehouse,
    required this.to_warehouse,
    required this.quantity,
  });

  static StockEntryItem fromJson(Map<String, dynamic> json) {
    return StockEntryItem(
      id: json["id"],
      idx: json["idx"],
      item_name: json["itemName"],
      from_warehouse: json["fromWarehouse"] ?? "",
      to_warehouse: json["toWarehouse"] ?? "",
      quantity: json["quantity"],
    );
  }
}
