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
}
