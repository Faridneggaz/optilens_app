// ignore_for_file: annotate_overrides
import '../../core/network/api_client.dart';
import '../../domain/entities/invoices_response.dart';
import '../../domain/failures/failures.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../mappers/json_mappers.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  InvoiceRepositoryImpl(this._client);

  final ApiClient _client;

  Future<InvoicesResponse> fetchInvoices({
    int limit = 20,
    int offset = 0,
    String? searchText,
    String? status,
  }) async {
    final query = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
    };
    if (searchText != null && searchText.isNotEmpty) {
      query['search_text'] = searchText;
    }
    if (status != null && status != 'All') {
      query['status'] = status;
    }
    final json = await _client.getCustomerMethod(
      'get_customer_invoices',
      query: query,
    );
    final message = _client.unwrap(json);
    if (message is! Map<String, dynamic> ||
        message['sales_invoices'] is! List ||
        message['pos_invoices'] is! List) {
      throw const RepositoryException('Invalid invoice list in response');
    }
    return InvoicesResponseMapper.fromJson(message);
  }
}
