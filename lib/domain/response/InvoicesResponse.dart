import 'sales_invoice.dart';

class InvoicesResponse {
  final String customer_code;
  final List<SalesInvoice> sales_invoices;
  final List<SalesInvoice> pos_invoices;
  InvoicesResponse({
    required this.customer_code,
    required this.sales_invoices,
    required this.pos_invoices,
  });
  static InvoicesResponse fromJson(Map<String, dynamic> json) {
    return InvoicesResponse(
      customer_code: json["message"]["customer_code"],
      sales_invoices: (json["message"]["sales_invoices"] as List)
          .map((s) => SalesInvoice.fromJson(s))
          .toList(),
      pos_invoices: (json["message"]["pos_invoices"] as List)
          .map((p) => SalesInvoice.fromJson(p))
          .toList(),
    );
  }
}
