import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../presentation/controllers/material_request_controller.dart';
import '../../presentation/controllers/user_dashboard_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/material_request_response.dart';
import '../../utils/mr_status_helper.dart';
import '../stock/document_ui.dart';
import 'mr_form_widgets.dart';

class MaterialRequestCard extends StatelessWidget {
  const MaterialRequestCard({
    super.key,
    required this.request,
    required this.controller,
  });

  final MaterialRequest request;
  final MaterialRequestController controller;

  @override
  Widget build(BuildContext context) {
    return DocumentListCard(
      onTap: () => Get.toNamed(
        AppRoutes.materialRequestDetail,
        arguments: request.name,
      ),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          translateMRPurpose(request.materialRequestType),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  MrStatusChip(status: request.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(request.transactionDate,
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(width: 12),
                  const Icon(Icons.business, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      request.company,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.warehouse_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _warehouseLabel(request),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${request.items.length} item${request.items.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, animation) {
                  final offset = Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offset, child: child),
                  );
                },
                child: canCreateStockEntryFromMR(
                  docstatus: request.docstatus,
                  status: request.status,
                  purpose: request.materialRequestType,
                )
                    ? Padding(
                        key: const ValueKey('create-se'),
                        padding: const EdgeInsets.only(top: 12),
                        child: Obx(() {
                          final busy = controller.isBusy(request.name);
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: busy
                                  ? null
                                  : () => _confirmCreateStockEntry(request),
                              icon: busy
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Icon(Icons.inventory_2_outlined,
                                      size: 16),
                              label: Text('create_stock_entry'.tr),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          );
                        }),
                      )
                    : (request.docstatus == 0 || request.status == 'Draft')
                        ? Padding(
                            key: const ValueKey('submit'),
                            padding: const EdgeInsets.only(top: 12),
                            child: Obx(() {
                              final busy = controller.isBusy(request.name);
                              return Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: busy
                                          ? null
                                          : () =>
                                              _confirmSubmit(request.name),
                                      icon: busy
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white))
                                          : const Icon(Icons.check, size: 16),
                                      label: Text('submit'.tr),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: busy
                                        ? null
                                        : () =>
                                            _confirmDelete(request.name),
                                    icon: const Icon(Icons.delete_outline,
                                        size: 16),
                                    label: Text('delete'.tr),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade50,
                                      foregroundColor: Colors.red,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          )
                        : const SizedBox(key: ValueKey('none')),
              ),
            ],
          ),
    );
  }

  Future<void> _confirmSubmit(String name) async {
    final ok = await showAppConfirmDialog(title: 'confirm_submit_mr'.tr);
    if (!ok) return;
    final res = await controller.submitRequest(name);
    if (res.isAuthHandled) return;
    if (!res.isSuccess) {
      Get.snackbar('error'.tr, res.error ?? 'error_occurred'.tr,
          backgroundColor: Colors.red.shade100, colorText: Colors.red);
    } else {
      Get.snackbar('success'.tr, 'mr_submitted'.tr,
          backgroundColor: Colors.green.shade100, colorText: Colors.green);
    }
  }

  Future<void> _confirmDelete(String name) async {
    final ok = await showAppConfirmDialog(
      title: 'confirm_delete_mr'.tr,
      confirmColor: Colors.red,
      confirmText: 'delete'.tr,
    );
    if (!ok) return;
    final res = await controller.deleteRequest(name);
    if (res.isAuthHandled) return;
    if (!res.isSuccess) {
      Get.snackbar('error'.tr, res.error ?? 'error_occurred'.tr,
          backgroundColor: Colors.red.shade100, colorText: Colors.red);
    } else {
      Get.snackbar('success'.tr, 'mr_deleted'.tr,
          backgroundColor: Colors.green.shade100, colorText: Colors.green);
    }
  }

  Future<void> _confirmCreateStockEntry(MaterialRequest request) async {
    final ok = await showAppConfirmDialog(
      title: 'confirm_create_stock_entry'.tr,
    );
    if (!ok) return;
    final res = await controller.createStockEntry(
      request.name,
      purpose: request.materialRequestType,
    );
    if (res.isAuthHandled) return;
    if (!res.isSuccess && res.stockEntryId == null) {
      Get.snackbar('error'.tr, res.error ?? 'error_occurred'.tr,
          backgroundColor: Colors.red.shade100, colorText: Colors.red);
      return;
    }
    final stockEntryId = res.navigableStockEntryId ?? '';
    if (Get.isRegistered<UserDashboardController>()) {
      Get.find<UserDashboardController>().onRefresh();
    }
    await controller.onRefresh();
    Get.snackbar('success'.tr, '${'stock_entry_created'.tr}$stockEntryId',
        backgroundColor: Colors.green.shade100, colorText: Colors.green);
    if (stockEntryId.isNotEmpty) {
      Get.toNamed(AppRoutes.stockEntry, arguments: {
        'name': stockEntryId,
      });
    }
  }

  static String _warehouseLabel(MaterialRequest request) {
    final purpose = normalizeMRPurpose(request.materialRequestType);
    if (purpose == 'Material Transfer') {
      if (request.fromWarehouse.isNotEmpty && request.warehouse.isNotEmpty) {
        return '${request.fromWarehouse} → ${request.warehouse}';
      }
    } else if (purpose == 'Material Issue') {
      return request.fromWarehouse.isNotEmpty
          ? request.fromWarehouse
          : request.warehouse;
    } else if (purpose == 'Material Receipt') {
      return request.warehouse;
    }
    if (request.fromWarehouse.isNotEmpty && request.warehouse.isNotEmpty) {
      return '${request.fromWarehouse} → ${request.warehouse}';
    }
    return request.fromWarehouse.isNotEmpty
        ? request.fromWarehouse
        : request.warehouse;
  }
}
