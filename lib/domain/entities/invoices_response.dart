import 'sales_invoice.dart';

class InvoicesResponse {
  final String customerCode;
  final List<SalesInvoice> salesInvoices;
  final List<SalesInvoice> posInvoices;
  final bool isSearch;

  InvoicesResponse({
    required this.customerCode,
    required this.salesInvoices,
    required this.posInvoices,
    this.isSearch = false,
  });
}
