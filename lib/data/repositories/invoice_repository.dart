import '../../core/network/api_client.dart';
import '../../domain/response/invoices_response.dart';

class InvoiceRepository {
  InvoiceRepository(this._client);

  final ApiClient _client;

  Future<InvoicesResponse> fetchInvoices(
    String customerCode, {
    int limit = 20,
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
      'get_invoices_by_customer_code',
      query: query,
      attachToken: false,
    );
    return InvoicesResponse.fromJson(json);
  }
}
