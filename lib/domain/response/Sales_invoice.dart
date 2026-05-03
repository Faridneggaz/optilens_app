class SalesInvoice {
  final String name;
  final String postingDate;
  final double grandTotal;
  final double outstandingAmount;
  final String status;
  final int isPos;

  SalesInvoice({
    required this.name,
    required this.postingDate,
    required this.grandTotal,
    required this.isPos,
    required this.outstandingAmount,
    required this.status,
  });

  static SalesInvoice fromJson(Map<String, dynamic> json) {
    return SalesInvoice(
      name: json["name"],
      postingDate: json["posting_date"],
      grandTotal: (json["grand_total"] as num).toDouble(),
      outstandingAmount: (json["outstanding_amount"] as num).toDouble(),
      status: json["status"],
      isPos: json["is_pos"],
    );
  }
}
