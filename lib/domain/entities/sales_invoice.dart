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
}
