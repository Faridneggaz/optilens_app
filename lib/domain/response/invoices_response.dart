import 'sales_invoice.dart';

class InvoicesResponse {
  final String customerCode;
  final List<SalesInvoice> salesInvoices;
  final List<SalesInvoice> posInvoices;

  InvoicesResponse({
    required this.customerCode,
    required this.salesInvoices,
    required this.posInvoices,
  });

  static InvoicesResponse fromJson(Map<String, dynamic> json) {
    return InvoicesResponse(
      customerCode: json["message"]["customer_code"],
      salesInvoices: (json["message"]["sales_invoices"] as List)
          .map((s) => SalesInvoice.fromJson(s))
          .toList(),
      posInvoices: (json["message"]["pos_invoices"] as List)
          .map((p) => SalesInvoice.fromJson(p))
          .toList(),
    );
  }
}
