// ignore_for_file: annotate_overrides
import '../../core/network/api_client.dart';
import '../../domain/entities/payment_response.dart';
import '../../domain/repositories/payment_repository.dart';
import '../mappers/json_mappers.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl(this._client);

  final ApiClient _client;
  static const int pageSize = 20;

  Future<PaymentResponse> fetchPayments(
    String customerCode, {
    int limit = pageSize,
    int offset = 0,
    String? searchText,
    String? status,
  }) async {
    final query = <String, String>{
      'code': customerCode,
      'limit': '$limit',
      'offset': '$offset',
    };
    if (searchText != null && searchText.isNotEmpty) {
      query['search_text'] = searchText;
    }
    if (status != null && status != 'All') {
      query['status'] = status;
    }
    final json = await _client.getMobile(
      'get_payments_by_customer_code',
      query: query,
      attachToken: false,
    );
    return PaymentResponseMapper.fromJson(json, limit);
  }
}
