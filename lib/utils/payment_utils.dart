import 'package:flutter/material.dart';

class PaidInvoice {
  final String invoiceId;
  final double amount;

  PaidInvoice({required this.invoiceId, required this.amount});
}

class PaymentItemData {
  final String paymentId;
  final String date;
  final List<PaidInvoice> invoices;

  PaymentItemData({
    required this.paymentId,
    required this.date,
    required this.invoices,
  });
  double get totalAmount => invoices.fold(0, (sum, inv) => sum + inv.amount);
}

class PaymentList extends StatefulWidget {
  final String globalTitle;
  final List<PaymentItemData> items;

  const PaymentList({
    super.key,
    required this.globalTitle,
    required this.items,
  });

  @override
  State<PaymentList> createState() => _PaymentListState();
}

class _PaymentListState extends State<PaymentList> {
  int? expandedIndex;

  void toggleExpand(int index) {
    setState(() {
      expandedIndex = expandedIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.globalTitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              widget.globalTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        ...List.generate(widget.items.length, (index) {
          final item = widget.items[index];
          final isExpanded = expandedIndex == index;

          return Column(
            children: [
              GestureDetector(
                onTap: () => toggleExpand(index),
                child: Card(
                  color: const Color.fromRGBO(254, 255, 255, 1),
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.2),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment for ${item.paymentId}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ' ${item.date}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${item.totalAmount.toStringAsFixed(2)} DA',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isExpanded
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(254, 255, 255, 1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color.fromRGBO(254, 255, 255, 1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Invoices Paid",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(0, 168, 156, 1),
                                ),
                              ),
                              const SizedBox(height: 10),
                              ..._buildPaidInvoices(item),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox(),
              ),
            ],
          );
        }),
      ],
    );
  }

  List<Widget> _buildPaidInvoices(PaymentItemData item) {
    return item.invoices.map((invoice) {
      return Card(
        color: const Color.fromRGBO(249, 250, 251, 1),
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.invoiceId,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Due: ${item.date}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                "${invoice.amount.toStringAsFixed(2)} DA",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
