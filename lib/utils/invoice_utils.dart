import 'package:flutter/material.dart';
import '../domain/response/sales_invoice.dart';
import 'status_color.dart';

class InvoiceItemData {
  final String title;
  final double ttc;
  final double price;
  final String postingDate;
  final String status;

  InvoiceItemData({
    required this.status,
    required this.title,
    required this.ttc,
    required this.postingDate,
    required this.price,
  });
}

class InvoiceList extends StatelessWidget {
  final List<InvoiceItemData> items;
  final String invoiceType;

  const InvoiceList({
    super.key,
    required this.items,
    required this.invoiceType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromRGBO(254, 255, 255, 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...items.map((item) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoiceType == "pos" ? "${item.title}" : item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.postingDate,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${item.price.toStringAsFixed(2)} DA",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),

                      if (item.ttc != 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: getStatusColor(item.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "Debt: ${item.ttc.toStringAsFixed(2)} DA",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: getStatusColor(item.status),
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),

                      Text(
                        "● ${item.status}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: getStatusColor(item.status),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

List<InvoiceItemData> convertToInvoiceItemData(List<SalesInvoice> invoices) {
  return invoices.map((invoice) {
    return InvoiceItemData(
      title: invoice.name,
      postingDate: invoice.posting_date,
      ttc: invoice.outstanding_amount,
      price: invoice.grand_total,
      status: invoice.status,
    );
  }).toList();
}
