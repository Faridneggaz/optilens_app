import '../entities/payment_response.dart';

abstract class PaymentRepository {
  Future<PaymentResponse> fetchPayments(
    String customerCode, {
    int limit = 20,
    int offset = 0,
    String? searchText,
    String? status,
  });
}
