import '../entities/payment_response.dart';

abstract class PaymentRepository {
  Future<PaymentResponse> fetchPayments({
    int limit = 20,
    int offset = 0,
    String? searchText,
    String? status,
  });
}
