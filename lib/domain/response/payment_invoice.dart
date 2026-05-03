class PaymentInvoice {
  final String invoice;
  final double allocatedAmount;
  final String invoicePostingDate;
  final String invoiceStatus;
  final double invoiceTotal;
  final double invoiceOutstanding;

  PaymentInvoice({
    required this.invoice,
    required this.allocatedAmount,
    required this.invoicePostingDate,
    required this.invoiceStatus,
    required this.invoiceTotal,
    required this.invoiceOutstanding,
  });

  static PaymentInvoice fromJson(Map<String, dynamic> json) {
    return PaymentInvoice(
      invoice: json["invoice"],
      allocatedAmount: (json["allocated_amount"] as num).toDouble(),
      invoicePostingDate: json["invoice_posting_date"],
      invoiceStatus: json["invoice_status"],
      invoiceTotal: (json["invoice_total"] as num).toDouble(),
      invoiceOutstanding: (json["invoice_outstanding"] as num).toDouble(),
    );
  }
}
