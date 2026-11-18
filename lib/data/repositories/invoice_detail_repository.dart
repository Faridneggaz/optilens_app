// ignore_for_file: annotate_overrides
import '../../core/network/api_client.dart';
import '../../domain/entities/invoice_detail_response.dart';
import '../../domain/failures/failures.dart';
import '../../domain/repositories/invoice_detail_repository.dart';
import '../mappers/json_mappers.dart';

class InvoiceDetailRepositoryImpl implements InvoiceDetailRepository {
  InvoiceDetailRepositoryImpl(this._client);

  final ApiClient _client;

  Future<InvoiceDetailResponse> getInvoiceDetails({
    required String invoiceName,
  }) async {
    final json = await _client.getCustomerMethod(
      'get_single_invoice_details',
      query: {'invoice_name': invoiceName},
    );
    final message = _client.unwrap(json);
    if (message is! Map<String, dynamic> || message['invoice'] is! Map) {
      throw const RepositoryException('Missing invoice in response');
    }
    return InvoiceDetailResponseMapper.fromJson(message);
  }
}
