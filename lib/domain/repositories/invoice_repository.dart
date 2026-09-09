import '../entities/invoices_response.dart';

abstract class InvoiceRepository {
  Future<InvoicesResponse> fetchInvoices(
    String customerCode, {
    int limit = 20,
    int offset = 0,
    String? searchText,
    String? status,
  });
}
