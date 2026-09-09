import 'payment.dart';

class PaymentResponse {
  final List<Payment> payments;
  final bool hasMore;
  final bool isSearch;

  PaymentResponse({
    required this.payments,
    required this.hasMore,
    this.isSearch = false,
  });
}
