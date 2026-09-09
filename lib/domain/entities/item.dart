class Item {
  final String itemCode;
  final String itemName;
  final double rate;
  final String currency;
  final String uom;

  const Item({
    required this.itemCode,
    required this.itemName,
    required this.rate,
    this.currency = 'DZD',
    this.uom = 'Nos',
  });
}
