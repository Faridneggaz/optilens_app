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
    final json = await _client.postMobile(
      'get_single_invoice_details',
      body: {'invoice_name': invoiceName},
      attachToken: false,
    );
    final message = json['message'];
    if (message == null) {
      throw const RepositoryException('Empty message in response');
    }
    return InvoiceDetailResponseMapper.fromJson(
      Map<String, dynamic>.from(message as Map),
    );
  }
}
