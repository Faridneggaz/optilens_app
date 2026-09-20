import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../presentation/controllers/material_request_controller.dart';
import '../stock/document_ui.dart';

class MaterialRequestFilterBar extends StatelessWidget {
  const MaterialRequestFilterBar({super.key, required this.controller});

  final MaterialRequestController controller;

  static const _statuses = [
    'All',
    'Draft',
    'Pending',
    'Submitted',
    'Partially Ordered',
    'Partially Received',
    'Transferred',
    'Issued',
    'Received',
    'Cancelled',
    'Stopped',
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() => DocumentFilterBar(
          hint: 'search_mr_hint'.tr,
          statuses: _statuses,
          selectedStatus: controller.selectedStatus.value,
          onSearchChanged: (v) => controller.searchQuery.value = v,
          onStatusChanged: (v) {
            controller.selectedStatus.value = v;
            controller.onRefresh();
          },
        ));
  }
}
