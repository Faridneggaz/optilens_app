import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../application/controllers/material_request_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/employee_api.dart';
import '../../domain/response/material_request_response.dart';
import '../../utils/mr_status_helper.dart';

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.toNamed(
          AppRoutes.materialRequestDetail,
          arguments: request.name,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      request.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    translateMRStatus(request.status),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: getMRStatusColor(request.status),
                    ),
                  ),
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
                      request.fromWarehouse.isNotEmpty
                          ? '${request.fromWarehouse} → ${request.warehouse}'
                          : request.warehouse,
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
              if (request.docstatus == 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmSubmit(request.name),
                        icon: const Icon(Icons.check, size: 16),
                        label: Text('submit'.tr),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _confirmDelete(request.name),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: Text('delete'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSubmit(String name) {
    Get.defaultDialog(
      title: 'confirm_submit_mr'.tr,
      middleText: '',
      textConfirm: 'submit'.tr,
      textCancel: 'cancel'.tr,
      confirmTextColor: Colors.white,
      buttonColor: Colors.teal,
      onConfirm: () async {
        Get.back();
        Get.dialog(const Center(child: CircularProgressIndicator()),
            barrierDismissible: false);
        final res = await controller.submitRequest(name);
        Get.back();
        if (EmployeeApi.isAuthHandled(res)) return;
        if (res.containsKey('error')) {
          Get.snackbar('error'.tr, res['error'],
              backgroundColor: Colors.red.shade100, colorText: Colors.red);
        } else {
          Get.snackbar('success'.tr, 'mr_submitted'.tr,
              backgroundColor: Colors.green.shade100, colorText: Colors.green);
          controller.onRefresh();
        }
      },
    );
  }

  void _confirmDelete(String name) {
    Get.defaultDialog(
      title: 'confirm_delete_mr'.tr,
      middleText: '',
      textConfirm: 'delete'.tr,
      textCancel: 'cancel'.tr,
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        Get.dialog(const Center(child: CircularProgressIndicator()),
            barrierDismissible: false);
        final res = await controller.deleteRequest(name);
        Get.back();
        if (EmployeeApi.isAuthHandled(res)) return;
        if (res.containsKey('error')) {
          Get.snackbar('error'.tr, res['error'],
              backgroundColor: Colors.red.shade100, colorText: Colors.red);
        } else {
          Get.snackbar('success'.tr, 'mr_deleted'.tr,
              backgroundColor: Colors.green.shade100, colorText: Colors.green);
          controller.onRefresh();
        }
      },
    );
  }
}
