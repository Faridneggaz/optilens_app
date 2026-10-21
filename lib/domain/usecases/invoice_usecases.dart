import '../entities/invoice_detail_response.dart';
import '../entities/invoices_response.dart';
import '../repositories/invoice_detail_repository.dart';
import '../repositories/invoice_repository.dart';

class InvoiceUseCases {
  InvoiceUseCases(this._invoices, this._details);
  final InvoiceRepository _invoices;
  final InvoiceDetailRepository _details;

  Future<InvoicesResponse> fetchInvoices(
    String customerCode, {
    int limit = 20,
    int offset = 0,
    String? searchText,
    String? status,
  }) =>
      _invoices.fetchInvoices(
        customerCode,
        limit: limit,
        offset: offset,
        searchText: searchText,
        status: status,
      );

  Future<InvoiceDetailResponse> getInvoiceDetails(String invoiceName) =>
      _details.getInvoiceDetails(invoiceName: invoiceName);
}
