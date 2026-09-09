import '../entities/invoice_detail_response.dart';

abstract class InvoiceDetailRepository {
  Future<InvoiceDetailResponse> getInvoiceDetails({
    required String invoiceName,
  });
}
