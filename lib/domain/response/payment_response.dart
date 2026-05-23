import 'payment.dart';

class PaymentResponse {
  final List<Payment> payments;
  final bool hasMore;
  final bool isSearch;

  PaymentResponse({required this.payments, required this.hasMore, this.isSearch = false});

  static PaymentResponse fromJson(Map<String, dynamic> json, int limit) {
    final message = json["message"];
    List<Payment> list = [];
    bool isSearch = false;
    
    if (message is List) {
      list = message.map((p) => Payment.fromJson(p)).toList();
    } else if (message is Map && message.containsKey("payments")) {
      list = (message["payments"] as List)
          .map((p) => Payment.fromJson(p))
          .toList();
      isSearch = message["is_search"] ?? false;
    }

    return PaymentResponse(
      payments: list,
      hasMore: list.length >= limit,
      isSearch: isSearch,
    );
  }
}