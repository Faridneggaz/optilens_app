class PaymentInvoice {
  final String invoice;
  final double allocated_amount;
  final String invoice_posting_date;
  final String invoice_status;
  final double invoice_total;
  final double invoice_outstanding;

  PaymentInvoice({
    required this.invoice,
    required this.allocated_amount,
    required this.invoice_posting_date,
    required this.invoice_status,
    required this.invoice_total,
    required this.invoice_outstanding,
  });

  static PaymentInvoice fromJson(Map<String, dynamic> json) {
    return PaymentInvoice(
      invoice: json["invoice"],
      allocated_amount: json["allocated_amount"],
      invoice_posting_date: json["invoice_posting_date"],
      invoice_status: json["invoice_status"],
      invoice_total: json["invoice_total"],
      invoice_outstanding: json["invoice_outstanding"],
    );
  }
}
