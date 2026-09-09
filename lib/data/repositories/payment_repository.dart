import '../../core/network/api_client.dart';
import '../../domain/response/payment_response.dart';

class PaymentRepository {
  PaymentRepository(this._client);

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
    return PaymentResponse.fromJson(json, limit);
  }
}
