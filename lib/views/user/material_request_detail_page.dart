import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../presentation/controllers/material_request_detail_controller.dart';
import '../../presentation/controllers/user_dashboard_controller.dart';
import '../../widgets/header.dart';
import '../../presentation/controllers/language_controller.dart';
import '../../app/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../utils/mr_status_helper.dart';
import '../../widgets/material_request/mr_form_widgets.dart';
import '../../widgets/stock/document_ui.dart';

class MaterialRequestDetailPage extends StatelessWidget {
  const MaterialRequestDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
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

        return Scaffold(
          backgroundColor: AppColors.scaffoldTint,
          body: Column(
            children: [
              AppHeader(title: mr.name, customer: null, customerCode: ''),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => c.fetchDetail(),
                  color: AppColors.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              translateMRPurpose(mr.materialRequestType),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          MrStatusChip(status: mr.status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      MrSectionCard(
                        title: 'mr_details_section'.tr,
                        children: [
                          MrInfoRow(label: 'select_company'.tr, value: mr.company),
                          MrInfoRow(
                            label: 'transaction_date'.tr,
                            value: mr.transactionDate,
                          ),
                          MrInfoRow(
                            label: 'required_by'.tr,
                            value: mr.scheduleDate,
                          ),
                        ],
                      ),
                      if (needsSourceWarehouse(mr.materialRequestType) ||
                          needsTargetWarehouse(mr.materialRequestType))
                        MrSectionCard(
                          title: 'mr_warehouses_section'.tr,
                          children: [
                            if (needsSourceWarehouse(mr.materialRequestType))
                              DocumentWarehouseBox(
                                title: 'warehouse_from'.tr,
                                value: mr.fromWarehouse.isNotEmpty
                                    ? mr.fromWarehouse
                                    : mr.warehouse,
                              ),
                            if (needsSourceWarehouse(mr.materialRequestType) &&
                                needsTargetWarehouse(mr.materialRequestType))
                              const SizedBox(height: 12),
                            if (needsTargetWarehouse(mr.materialRequestType))
                              DocumentWarehouseBox(
                                title: 'warehouse_to'.tr,
                                value: mr.warehouse,
                              ),
                          ],
                        ),
                      MrSectionCard(
                        title: 'items_label'.tr,
                        children: [
                          if (mr.items.isEmpty)
                            Text('no_material_requests'.tr,
                                style: const TextStyle(color: Colors.grey))
                          else
                            ...mr.items.map((item) {
                              return DocumentItemLine(
                                code: item.itemCode.isNotEmpty
                                    ? item.itemCode
                                    : item.itemName,
                                qty: item.qty.toString(),
                              );
                            }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Obx(() {
                  Widget button;
                  if (c.isBusy.value) {
                    button = const SizedBox(
                      key: ValueKey('busy'),
                      height: 52,
                      child: Center(
                          child: CircularProgressIndicator(color: Colors.teal)),
                    );
                  } else if (canCreateStockEntryFromMR(
                    docstatus: mr.docstatus,
                    status: mr.status,
                    purpose: mr.materialRequestType,
                  )) {
                    button = DocumentPrimaryButton(
                      key: const ValueKey('create-se'),
                      label: 'create_stock_entry'.tr,
                      icon: Icons.inventory_2_outlined,
                      onPressed: () =>
                          _handleCreateStockEntry(mr.name, c, context),
                    );
                  } else if (mr.docstatus == 0 || mr.status == 'Draft') {
                    button = DocumentPrimaryButton(
                      key: const ValueKey('submit'),
                      label: 'submit'.tr,
                      icon: Icons.check,
                      onPressed: () => _handleSubmit(mr.name, c, context),
                    );
                  } else {
                    button = const SizedBox(key: ValueKey('none'), height: 8);
                  }
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      final offset = Tween<Offset>(
                        begin: const Offset(0, 0.35),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: offset, child: child),
                      );
                    },
                    child: button,
                  );
                }),
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _handleSubmit(
      String name, MaterialRequestDetailController c, BuildContext context) async {
    final ok = await showAppConfirmDialog(
      title: 'confirm_submit_mr'.tr,
    );
    if (!ok) return;
    final result = await c.submitRequest();
    if (result.isAuthHandled) return;
    if (result.isSuccess) {
      Get.snackbar('success'.tr, 'mr_submitted'.tr,
          backgroundColor: Colors.green, colorText: Colors.white);
    } else {
      Get.snackbar('error'.tr, result.error ?? 'error_occurred'.tr,
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _handleCreateStockEntry(
      String name, MaterialRequestDetailController c, BuildContext context) async {
    final ok = await showAppConfirmDialog(
      title: 'confirm_create_stock_entry'.tr,
    );
    if (!ok) return;
    final result = await c.createStockEntry();
    if (result.isAuthHandled) return;
    if (result.isSuccess || result.stockEntryId != null) {
      final stockEntryId = result.navigableStockEntryId ?? '';
      if (Get.isRegistered<UserDashboardController>()) {
        Get.find<UserDashboardController>().onRefresh();
      }
      Get.snackbar('success'.tr, '${'stock_entry_created'.tr}$stockEntryId',
          backgroundColor: Colors.green, colorText: Colors.white);
      if (stockEntryId.isNotEmpty) {
        Get.toNamed(AppRoutes.stockEntry, arguments: {
          'name': stockEntryId,
        });
      }
    } else {
      Get.snackbar('error'.tr, result.error ?? 'error_occurred'.tr,
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
