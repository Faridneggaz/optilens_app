import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../application/controllers/material_request_controller.dart';
import '../../core/theme/app_colors.dart';

class MaterialRequestFilterBar extends StatelessWidget {
  const MaterialRequestFilterBar({super.key, required this.controller});

  final MaterialRequestController controller;

  static const _statuses = [
    'All',
    'Draft',
    'Pending',
    'Submitted',
    'Partially Received',
    'Received',
    'Cancelled',
    'Stopped',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.scaffold,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'search_mr_hint'.tr,
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13),
                        border: InputBorder.none,
                      ),
                      onChanged: (v) => controller.searchQuery.value = v,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.scaffold,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Obx(() => DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: controller.selectedStatus.value,
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.grey),
                      items: _statuses
                          .map((value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value == 'All' ? 'filter_all'.tr : value,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          controller.selectedStatus.value = v;
                          controller.onRefresh();
                        }
                      },
                    ),
                  )),
            ),
          ),
        ],
      ),
    );
  }
}
