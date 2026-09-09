// ignore_for_file: annotate_overrides
import '../../core/network/api_client.dart';
import '../../domain/entities/invoices_response.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../mappers/json_mappers.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  InvoiceRepositoryImpl(this._client);

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
    return InvoicesResponseMapper.fromJson(json);
  }
}
