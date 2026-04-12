class CartItem {
  final String itemCode;
  final String itemName;
  final double rate;
  int quantity;

  CartItem({
    required this.itemCode,
    required this.itemName,
    required this.rate,
    this.quantity = 1,
  });

  // Pour envoyer au format JSON attendu par ton API Python
  Map<String, dynamic> toJson() => {
    "item_code": itemCode,
    "qty": quantity,
  };
}