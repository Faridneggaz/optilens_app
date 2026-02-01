class InvoiceDetailResponse {
  final InvoiceDetail invoice;
  final List<InvoiceItem> items;

  InvoiceDetailResponse({
    required this.invoice,
    required this.items,
  });

  factory InvoiceDetailResponse.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailResponse(
      invoice: InvoiceDetail.fromJson(json['invoice'] ?? {}),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => InvoiceItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class InvoiceDetail {
  final String name;
  final String postingDate;
  final double grandTotal;
  final double outstandingAmount;
  final String status;
  final double totalQty;
  final String? customer;

  InvoiceDetail({
    required this.name,
    required this.postingDate,
    required this.grandTotal,
    required this.outstandingAmount,
    required this.status,
    this.customer,
    this.totalQty = 0,
  });

  factory InvoiceDetail.fromJson(Map<String, dynamic> json) {
    return InvoiceDetail(
      name: json['name'] ?? '',
      postingDate: json['posting_date'] ?? '',
      grandTotal: _toDouble(json['grand_total']),
      outstandingAmount: _toDouble(json['outstanding_amount']),
      status: json['status'] ?? '',
      totalQty: _toDouble(json['total_qty']),
      customer: json['customer'],
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class InvoiceItem {
  final String itemCode;
  final String itemName;
  final double qty;
  final double rate;
  final double amount;
  

  InvoiceItem({
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.rate,
    required this.amount,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      itemCode: json['item_code'] ?? '',
      itemName: json['item_name'] ?? json['item_code'] ?? '',
      qty: _toDouble(json['qty']),
      rate: _toDouble(json['rate']),
      amount: _toDouble(json['amount']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}