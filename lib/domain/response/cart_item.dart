/// A single item in the customer's cart.
/// Only [itemCode] and [quantity] are sent to the backend on order submission —
/// the backend resolves the price from the customer's price list itself.
class CartItem {
  final String itemCode;
  final String itemName;
  final double rate;
  final String currency;
  final String uom;
  int quantity;

  CartItem({
    required this.itemCode,
    required this.itemName,
    required this.rate,
    this.currency = 'DZD',
    this.uom = 'Nos',
    this.quantity = 1,
  });

  double get lineTotal => rate * quantity;

  /// Only item_code + qty — backend fetches rate from price list.
  Map<String, dynamic> toJson() => {
        'item_code': itemCode,
        'qty': quantity,
      };
}