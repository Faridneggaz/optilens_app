import 'Payment.dart';

class PaymentResponse {
  final List<Payment> payments;

  PaymentResponse({required this.payments});

  static PaymentResponse fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      payments: (json["message"]["payments"] as List)
          .map((p) => Payment.fromJson(p))
          .toList(),
    );
  }
}
