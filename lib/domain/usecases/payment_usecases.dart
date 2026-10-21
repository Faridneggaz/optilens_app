import '../entities/payment_response.dart';
import '../repositories/payment_repository.dart';

class PaymentUseCases {
  PaymentUseCases(this._repo);
  final PaymentRepository _repo;

  Future<PaymentResponse> fetchPayments(
    String customerCode, {
    int limit = 20,
    int offset = 0,
    String? searchText,
    String? status,
  }) =>
      _repo.fetchPayments(
        customerCode,
        limit: limit,
        offset: offset,
        searchText: searchText,
        status: status,
      );
}
