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

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        itemCode: json['item_code']?.toString() ?? '',
        itemName: json['item_name']?.toString() ?? '',
        rate: double.tryParse(
        (json['standard_rate'] ?? json['rate'] ?? 0.0).toString()
      ) ?? 0.0,
        currency: json['currency']?.toString() ?? 'DZD',
        uom: json['uom']?.toString() ?? 'Nos',
      );
}
