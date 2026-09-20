import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../presentation/controllers/stock_entry_details_controller.dart';
import '../../presentation/controllers/user_dashboard_controller.dart';
import '../../domain/entities/stock_entry_item.dart' as model;
import '../../widgets/header.dart';
import '../../presentation/controllers/language_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/material_request/mr_form_widgets.dart';
import '../../widgets/stock/document_ui.dart';
import '../../widgets/stock/add_stock_item_sheet.dart';

class StockEntryPage extends StatelessWidget {
  const StockEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<StockEntryDetailsController>();

    return GetBuilder<LanguageController>(
      builder: (_) => Obx(() {
        if (c.isLoading.value) {
          return const Scaffold(
            backgroundColor: AppColors.scaffoldTint,
            body: Center(child: CircularProgressIndicator(color: Colors.teal)),
          );
        }

        final data = c.data.value;
        if (data == null) {
          return Scaffold(
            backgroundColor: AppColors.scaffoldTint,
            body: Center(child: Text('failed_load_stock'.tr)),
          );
        }

        final se = data.stockEntry;

        return Scaffold(
          backgroundColor: AppColors.scaffoldTint,
          resizeToAvoidBottomInset: true,
          body: Column(
            children: [
              AppHeader(title: se.name, customer: null, customerCode: ''),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: c.onRefresh,
                  color: AppColors.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'nav_stock_entries'.tr,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          MrStatusChip(status: se.status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      MrSectionCard(
                        title: 'mr_details_section'.tr,
                        children: [
                          MrInfoRow(
                              label: 'select_company'.tr, value: se.company),
                          MrInfoRow(
                            label: 'transaction_date'.tr,
                            value: se.postingDate,
                          ),
                        ],
                      ),
                      if (se.fromWarehouse.isNotEmpty ||
                          se.toWarehouse.isNotEmpty)
                        MrSectionCard(
                          title: 'mr_warehouses_section'.tr,
                          children: [
                            if (se.fromWarehouse.isNotEmpty)
                              DocumentWarehouseBox(
                                title: 'warehouse_from'.tr,
                                value: se.fromWarehouse,
                                validated: c.fromWarehouseValidated.value,
                                enabled: c.isPending,
                                onTap: () => c.fromWarehouseValidated.value =
                                    !c.fromWarehouseValidated.value,
                              ),
                            if (se.fromWarehouse.isNotEmpty &&
                                se.toWarehouse.isNotEmpty)
                              const SizedBox(height: 12),
                            if (se.toWarehouse.isNotEmpty)
                              DocumentWarehouseBox(
                                title: 'warehouse_to'.tr,
                                value: se.toWarehouse,
                                validated: c.toWarehouseValidated.value,
                                enabled: c.isPending,
                                onTap: () => c.toWarehouseValidated.value =
                                    !c.toWarehouseValidated.value,
                              ),
                          ],
                        ),
                      MrSectionCard(
                        title: 'items_label'.tr,
                        children: [
                          if (c.isPending)
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: const Icon(Icons.add_circle,
                                    color: AppColors.primary, size: 28),
                                onPressed: () => _showAddItemSheet(context, c),
                              ),
                            ),
                          if (data.items.isEmpty)
                            Text('no_stock_entries'.tr,
                                style: const TextStyle(color: Colors.grey))
                          else
                            ...data.items.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final item = entry.value;
                              final isValidated =
                                  c.validatedItemIndices.contains(idx);
                              final code = item.itemCode.isNotEmpty
                                  ? item.itemCode
                                  : item.itemName;
                              return DocumentItemLine(
                                key: ValueKey(
                                    '${item.itemCode}_${item.idx}_$idx'),
                                code: code,
                                qty: item.quantity.toString(),
                                qtyWidget: (c.isPending && !isValidated)
                                    ? SizedBox(
                                        width: 64,
                                        child: TextFormField(
                                          key: ValueKey(
                                              'qty_${item.itemCode}_$idx'),
                                          initialValue:
                                              item.quantity.toString(),
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 8),
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (v) => item.quantity =
                                              int.tryParse(v) ?? item.quantity,
                                        ),
                                      )
                                    : null,
                                trailing: c.isPending
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            visualDensity:
                                                VisualDensity.compact,
                                            icon: Icon(
                                              Icons.check_circle,
                                              color: isValidated
                                                  ? AppColors.primary
                                                  : Colors.grey,
                                            ),
                                            onPressed: () =>
                                                c.toggleItemValidation(idx),
                                          ),
                                          if (!isValidated)
                                            IconButton(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
                                                  size: 20),
                                              onPressed: () =>
                                                  c.removeItem(idx),
                                            ),
                                        ],
                                      )
                                    : null,
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
                  if (c.isSubmitting.value) {
                    button = const SizedBox(
                      key: ValueKey('busy'),
                      height: 52,
                      child: Center(
                        child:
                            CircularProgressIndicator(color: Colors.teal),
                      ),
                    );
                  } else if (c.isPending) {
                    button = DocumentPrimaryButton(
                      key: const ValueKey('approve'),
                      label: 'btn_approve'.tr,
                      icon: Icons.check,
                      enabled: c.canApprove,
                      onPressed: () => _handleApprove(c),
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
                        child: SlideTransition(
                            position: offset, child: child),
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

  Future<void> _handleApprove(StockEntryDetailsController c) async {
    final result = await c.approveStockEntry();
    if (result.isAuthHandled) return;
    if (result.isSuccess) {
      if (Get.isRegistered<UserDashboardController>()) {
        Get.find<UserDashboardController>().onRefresh();
      }
      Get.snackbar(
        'success'.tr,
        result.detail ?? 'approve_success'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'error'.tr,
        result.error ?? 'approve_error'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _showAddItemSheet(
    BuildContext context,
    StockEntryDetailsController c,
  ) async {
    final result = await showModalBottomSheet<AddStockItemResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddStockItemSheet(searchItems: c.searchItems),
    );
    if (result == null) return;

    final se = c.data.value?.stockEntry;
    if (se == null) return;

    c.addItem(model.StockEntryItem(
      id: '',
      idx: (c.data.value?.items.length ?? 0) + 1,
      itemCode: result.itemCode,
      itemName: result.itemName,
      fromWarehouse: se.fromWarehouse,
      toWarehouse: se.toWarehouse,
      quantity: result.quantity,
    ));
  }
}
