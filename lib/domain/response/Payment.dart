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

  static Payment fromJson(Map<String, dynamic> json) {
    return Payment(
      name: json["name"] ?? "",
      postingDate: json["posting_date"] ?? "",
      paidAmount: (json["paid_amount"] as num?)?.toDouble() ?? 0.0,
      paymentType: json["payment_type"] ?? "",
      modeOfPayment: json["mode_of_payment"],
      invoicesPayed: json["invoices_payed"] != null 
          ? (json["invoices_payed"] as List)
              .map((i) => PaymentInvoice.fromJson(i))
              .toList()
          : [],
    );
  }
}
