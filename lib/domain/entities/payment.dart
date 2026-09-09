import 'payment_invoice.dart';

class Payment {
  final String name;
  final String postingDate;
  final double paidAmount;
  final String paymentType;
  final String? modeOfPayment;
  final List<PaymentInvoice> invoicesPayed;

  Payment({
    required this.name,
    required this.postingDate,
    required this.paidAmount,
    required this.paymentType,
    this.modeOfPayment,
    required this.invoicesPayed,
  });
}
