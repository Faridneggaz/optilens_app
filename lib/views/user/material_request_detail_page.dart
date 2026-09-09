import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../presentation/controllers/material_request_detail_controller.dart';
import '../../widgets/header.dart';
import '../../presentation/controllers/language_controller.dart';
import '../../core/services/session_service.dart';
import '../../app/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
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
            backgroundColor: AppColors.scaffoldTint,
            body: Center(child: CircularProgressIndicator(color: Colors.teal)),
          );
        }

        final mr = c.mr.value;
        if (mr == null) {
          return Scaffold(
            backgroundColor: AppColors.scaffoldTint,
            body: Center(child: Text('failed_load_stock'.tr)),
          );
        }

        const headerStyle = TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black);

        return Scaffold(
          backgroundColor: AppColors.scaffoldTint,
          body: Column(
            children: [
              AppHeader(title: mr.name, customer: null, customerCode: ''),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => c.fetchDetail(),
                  color: AppColors.primary,
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

              // Bottom action area
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: Obx(() {
                    final isBusy = c.isLoading.value;
                    if (isBusy) {
                      return const Center(child: CircularProgressIndicator(color: Colors.teal));
                    }
                    if (mr.docstatus == 0) {
                      return _actionButton(
                        label: 'submit'.tr,
                        icon: Icons.check,
                        color: AppColors.primary,
                        onPressed: () => _handleSubmit(mr.name, c, context),
                      );
                    }
                    if (mr.status == 'Pending' && mr.materialRequestType == 'Material Transfer') {
                      return _actionButton(
                        label: 'create_transfer'.tr,
                        icon: Icons.swap_horiz,
                        color: Colors.blue.shade600,
                        onPressed: () => _handleCreateTransfer(mr.name, c, context),
                      );
                    }
                    return const SizedBox(height: 16);
                  }),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleSubmit(String name, MaterialRequestDetailController c, BuildContext context) {
    Get.defaultDialog(
      title: 'confirm'.tr,
      middleText: 'confirm_submit_mr'.tr,
      textConfirm: 'confirm'.tr,
      textCancel: 'cancel'.tr,
      confirmTextColor: Colors.white,
      buttonColor: Colors.teal,
      onConfirm: () async {
        Get.back();
        c.isLoading.value = true;
        final result = await c.submitRequest();
        c.isLoading.value = false;
        if (result.isAuthHandled) {
          return;
        }
        if (result.isSuccess) {
          Get.snackbar('success'.tr, 'mr_submitted'.tr,
              backgroundColor: Colors.green, colorText: Colors.white);
        } else {
          Get.snackbar('error'.tr, result.error ?? 'error_occurred'.tr,
              backgroundColor: Colors.red, colorText: Colors.white);
        }
      },
    );
  }

  void _handleCreateTransfer(String name, MaterialRequestDetailController c, BuildContext context) {
    Get.defaultDialog(
      title: 'confirm_create_transfer'.tr,
      middleText: 'confirm_create_transfer_msg'.tr,
      textConfirm: 'confirm'.tr,
      textCancel: 'cancel'.tr,
      confirmTextColor: Colors.white,
      buttonColor: Colors.teal,
      onConfirm: () async {
        Get.back();
        c.isLoading.value = true;
        final result = await c.createTransfer();
        c.isLoading.value = false;
        if (result.isAuthHandled) {
          return;
        }
        if (result.isSuccess || result.stockEntryId != null) {
          final stockEntryId = result.stockEntryId ?? '';
          Get.snackbar('success'.tr, '${'stock_entry_created'.tr}$stockEntryId',
              backgroundColor: Colors.green, colorText: Colors.white);
          Get.toNamed(AppRoutes.stockEntry, arguments: {
            'name': stockEntryId,
            'token': Get.find<SessionService>().authToken,
          });
        } else {
          Get.snackbar('error'.tr, result.error ?? 'error_occurred'.tr,
              backgroundColor: Colors.red, colorText: Colors.white);
        }
      },
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
}
