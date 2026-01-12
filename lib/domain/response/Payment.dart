import 'PaymentInvoice.dart';

class Payment {
  final String name;
  final String posting_date;
  final double paid_amount;
  final String payment_type;
  final String? mode_of_payment;
  final List<PaymentInvoice> invoices_payed;

  Payment({
    required this.name,
    required this.posting_date,
    required this.paid_amount,
    required this.payment_type,
    this.mode_of_payment,
    required this.invoices_payed,
  });

  static Payment fromJson(Map<String, dynamic> json) {
    return Payment(
      name: json["name"],
      posting_date: json["posting_date"],
      paid_amount: json["paid_amount"],
      payment_type: json["payment_type"],
      mode_of_payment: json["mode_of_payment"],
      invoices_payed: (json["invoices_payed"] as List)
          .map((i) => PaymentInvoice.fromJson(i))
          .toList(),
    );
  }
}
