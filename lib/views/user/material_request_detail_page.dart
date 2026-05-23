import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../application/controllers/material_request_detail_controller.dart';
import '../../widgets/header.dart';
import '../../../application/controllers/language_controller.dart';

class MaterialRequestDetailPage extends StatelessWidget {
  const MaterialRequestDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller is registered by bindings. Fallback to Get.find.
    final c = Get.find<MaterialRequestDetailController>();

    return GetBuilder<LanguageController>(
      builder: (_) => Obx(() {
        if (c.isLoading.value) {
          return const Scaffold(
            backgroundColor: Color.fromARGB(255, 247, 255, 254),
            body: Center(child: CircularProgressIndicator(color: Colors.teal)),
          );
        }

        final mr = c.mr.value;
        if (mr == null) {
          return Scaffold(
            backgroundColor: const Color.fromARGB(255, 247, 255, 254),
            body: Center(child: Text('failed_load_stock'.tr)),
          );
        }

        const headerStyle = TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black);

        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 247, 255, 254),
          body: Column(
            children: [
              AppHeader(title: mr.name, customer: null, customerCode: ''),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => c.fetchDetail(),
                  color: const Color.fromARGB(255, 0, 167, 155),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Text('${'date_label_stock'.tr}${mr.transactionDate}',
                            style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 12),
                        Text('${'company_label'.tr}${mr.company}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 20),

                        // Warehouse Green Cards based on purpose
                        if (mr.materialRequestType == 'Material Transfer') ...[
                          if (mr.fromWarehouse.isNotEmpty)
                            _warehouseBox(
                              title: 'warehouse_from'.tr,
                              value: mr.fromWarehouse,
                            ),
                          const SizedBox(height: 12),
                          if (mr.warehouse.isNotEmpty)
                            _warehouseBox(
                              title: 'warehouse_to'.tr,
                              value: mr.warehouse,
                            ),
                        ] else if (mr.materialRequestType == 'Material Issue') ...[
                          if (mr.warehouse.isNotEmpty || mr.fromWarehouse.isNotEmpty)
                            _warehouseBox(
                              title: 'warehouse_from'.tr,
                              value: mr.warehouse.isNotEmpty ? mr.warehouse : mr.fromWarehouse,
                            ),
                        ] else if (mr.materialRequestType == 'Material Receipt' || mr.materialRequestType == 'Purchase') ...[
                          if (mr.warehouse.isNotEmpty)
                            _warehouseBox(
                              title: 'warehouse_to'.tr,
                              value: mr.warehouse,
                            ),
                        ] else ...[
                          // Default fallback
                          if (mr.fromWarehouse.isNotEmpty)
                            _warehouseBox(
                              title: 'warehouse_from'.tr,
                              value: mr.fromWarehouse,
                            ),
                          const SizedBox(height: 12),
                          if (mr.warehouse.isNotEmpty)
                            _warehouseBox(
                              title: 'warehouse_to'.tr,
                              value: mr.warehouse,
                            ),
                        ],
                        const SizedBox(height: 25),

                        Text('items_label'.tr,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),

                        // Column headers
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text('item_name'.tr,
                                    textAlign: TextAlign.left,
                                    style: headerStyle),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('qty_header'.tr,
                                    textAlign: TextAlign.center,
                                    style: headerStyle),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('status_header'.tr,
                                    textAlign: TextAlign.center,
                                    style: headerStyle),
                              ),
                            ],
                          ),
                        ),
                        const Divider(thickness: 1.0, color: Colors.black26),

                        ...mr.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    item.itemCode.isNotEmpty
                                        ? item.itemCode
                                        : item.itemName,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    item.qty.toString(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Colors.teal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom status button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: mr.docstatus == 0
                        ? () => c.submitRequest()
                        : () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      mr.docstatus == 0
                          ? 'submit'.tr
                          : _translateStatus(mr.status),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _warehouseBox({required String title, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(color: Colors.teal.shade700, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'Draft':
        return 'Brouillon';
      case 'Submitted':
        return 'Soumis';
      case 'Pending':
        return 'En attente';
      case 'Partially Received':
        return 'Partiellement reçu';
      case 'Received':
        return 'Reçu';
      case 'Stopped':
        return 'Arrêté';
      case 'Cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }
}
