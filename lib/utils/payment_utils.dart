import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../application/controllers/payment_controller.dart';

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

class PaymentList extends StatelessWidget {
  final String globalTitle;
  final List<PaymentItemData> items;

  const PaymentList({
    super.key,
    required this.globalTitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PaymentController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (globalTitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              globalTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        
        ...List.generate(items.length, (index) {
          final item = items[index];

          return Obx(() {
            final isExpanded = controller.expandedIndex.value == index;

            return Card(
            color: const Color.fromRGBO(254, 255, 255, 1),
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.1),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isExpanded 
                  ? const BorderSide(color: Color(0xFF00A89C), width: 1.5) 
                  : BorderSide.none,
            ),
            child: Column(
              children: [

                InkWell( 
                  onTap: () => controller.toggleExpand(index),
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(12),
                    bottom: Radius.circular(isExpanded ? 0 : 12),
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Montant Global
                        Text(
                          '${item.totalAmount.toStringAsFixed(0)} DA',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF004D40),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Flèche animée
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),


                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [

                        Divider(color: Colors.grey.withOpacity(0.2)), 
                        const SizedBox(height: 10),
                        

                        ..._buildTimelineInvoices(item),
                      ],
                    ),
                  ),
              ],
            ),
          );
        });
        }),
      ],
    );
  }


  List<Widget> _buildTimelineInvoices(PaymentItemData item) {
    return List.generate(item.invoices.length, (i) {
      final invoice = item.invoices[i];
      final isLast = i == item.invoices.length - 1;

      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            SizedBox(
              width: 30,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  if (!isLast)
                    Positioned(
                      top: 12, bottom: 0, left: 14,
                      child: Container(width: 2, color: Colors.grey.withOpacity(0.3)),
                    ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      invoice.invoiceId,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    Text(
                      "${invoice.amount.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}