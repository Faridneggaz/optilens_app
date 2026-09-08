import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../application/controllers/invoice_detail_controller.dart';
import '../../../application/controllers/language_controller.dart';

class InvoiceDetailPage extends StatelessWidget {
  const InvoiceDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(InvoiceDetailController());

    return GetBuilder<LanguageController>(
      builder: (_) => Scaffold(
        backgroundColor: const Color.fromARGB(255, 247, 255, 253),
        appBar: AppBar(
          title: const Text('',
              style: TextStyle(
                  color: Color(0xFF00A69C), fontWeight: FontWeight.bold)),
          backgroundColor: const Color.fromARGB(255, 247, 255, 253),
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
        ),

        body: Obx(() {
          if (c.isLoading.value) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF00A69C)));
          }
          if (c.error.value != null) {
            return Center(child: Text(c.error.value!));
          }
          final inv = c.invoiceData.value!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invoice #${inv.invoice.name}',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('${'issue_date_label'.tr}${inv.invoice.postingDate}',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 15)),

                  const SizedBox(height: 30),
                  Text('items_title'.tr,
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: inv.items.length,
                    itemBuilder: (context, index) {
                      final item = inv.items[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: Colors.grey.shade200))),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.itemName,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${'qty_label'.tr}${item.qty.toInt()}   ${'unit_price_label'.tr}${item.rate.toStringAsFixed(2)} DA',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                                '${item.amount.toStringAsFixed(2)} DA',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 35),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('total_colon'.tr,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      Text(
                          '${inv.invoice.grandTotal.toStringAsFixed(2)} DA',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),

                  const SizedBox(height: 40),

                  Center(
                    child: Text(
                      '${'status_colon'.tr}${inv.invoice.status}',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: c.getStatusColor(inv.invoice.status)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

}
