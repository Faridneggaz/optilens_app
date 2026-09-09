import '../../core/network/api_client.dart';
import '../../domain/response/invoice_detail_response.dart';
import 'repository_exception.dart';

class InvoiceDetailRepository {
  InvoiceDetailRepository(this._client);

  final ApiClient _client;

  Future<InvoiceDetailResponse> getInvoiceDetails({
    required String invoiceName,
  }) async {
    final json = await _client.postMobile(
      'get_single_invoice_details',
      body: {'invoice_name': invoiceName},
      attachToken: false,
    );
    final message = json['message'];
    if (message == null) {
      throw const RepositoryException('Empty message in response');
    }
    return InvoiceDetailResponse.fromJson(
      Map<String, dynamic>.from(message as Map),
    );
  }
}
