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

  factory StockEntryItem.fromJson(Map<String, dynamic> json) {
    return StockEntryItem(
      id: json["id"] ?? "",
      idx: json["idx"] ?? 0,
      itemCode: json["itemCode"] ?? "",
      itemName: json["itemName"] ?? "",
      fromWarehouse: json["fromWarehouse"] ?? "",
      toWarehouse: json["toWarehouse"] ?? "",
      quantity: (json["quantity"] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "itemName": itemCode,
      "quantity": quantity,
      "fromWarehouse": fromWarehouse,
      "toWarehouse": toWarehouse,
    };
  }
}
