class StockEntryItem {
  final String id;
  final int idx;
  final String item_code; 
  final String item_name;
  final String from_warehouse;
  final String to_warehouse;
  int quantity; 

  StockEntryItem({
    required this.id,
    required this.idx,
    required this.item_code,
    required this.item_name,
    required this.from_warehouse,
    required this.to_warehouse,
    required this.quantity,
  });

  factory StockEntryItem.fromJson(Map<String, dynamic> json) {
    return StockEntryItem(
      id: json["id"] ?? "",
      idx: json["idx"] ?? 0,
      item_code: json["itemCode"] ?? "",
      item_name: json["itemName"] ?? "",
      from_warehouse: json["fromWarehouse"] ?? "",
      to_warehouse: json["toWarehouse"] ?? "",
      quantity: (json["quantity"] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "itemName": item_code,
      "quantity": quantity,
      "fromWarehouse": from_warehouse,
      "toWarehouse": to_warehouse,
    };
  }
}
