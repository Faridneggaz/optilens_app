class InvoiceDetailResponse {
  final InvoiceDetail invoice;
  final List<InvoiceItem> items;

  InvoiceDetailResponse({
    required this.invoice,
    required this.items,
  });
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
}
