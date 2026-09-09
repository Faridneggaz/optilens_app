import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../presentation/controllers/material_request_controller.dart';
import '../../presentation/controllers/language_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/header.dart';
import '../../widgets/material_request/create_material_request_sheet.dart';
import '../../widgets/material_request/material_request_card.dart';
import '../../widgets/material_request/material_request_filter_bar.dart';

class MaterialRequestPage extends StatelessWidget {
  const MaterialRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MaterialRequestController>();

    return GetBuilder<LanguageController>(
      builder: (_) => Scaffold(
        backgroundColor: AppColors.scaffold,
        floatingActionButton: Obx(() {
          if (!c.isSearching.value) {
            return FloatingActionButton.extended(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => CreateMaterialRequestSheet(c: c),
              ),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text('new_request'.tr,
                  style: const TextStyle(color: Colors.white)),
            );
          }
          return const SizedBox.shrink();
        }),
        body: Column(
          children: [
            AppHeader(
                title: 'material_requests'.tr,
                customer: null,
                customerCode: ''),
            MaterialRequestFilterBar(controller: c),
            Expanded(
              child: Obx(() {
                if (c.isLoading.value || c.isSearching.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (c.displayList.isEmpty) {
                  return Center(
                    child: Text('no_material_requests'.tr,
                        style: const TextStyle(color: Colors.grey)),
                  );
                }
                return RefreshIndicator(
                  onRefresh: c.onRefresh,
                  color: AppColors.primary,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    itemCount: c.displayList.length + 1,
                    itemBuilder: (context, index) {
                      if (index == c.displayList.length) {
                        return _LoadMoreFooter(controller: c);
                      }
                      return MaterialRequestCard(
                        request: c.displayList[index],
                        controller: c,
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({required this.controller});

  final MaterialRequestController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.searchQuery.value.isNotEmpty ||
        controller.isSearching.value) {
      return const SizedBox.shrink();
    }
    if (!controller.hasMore.value && controller.materialRequests.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
            child: Text('all_entries_loaded'.tr,
                style: const TextStyle(color: Colors.grey))),
      );
    }
    if (controller.isLoadingMore.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (controller.hasMore.value && controller.materialRequests.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ElevatedButton(
          onPressed: controller.onLoadMore,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.scaffold,
            foregroundColor: Colors.teal,
            elevation: 0,
            side: const BorderSide(color: Colors.teal),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: Text('load_more'.tr,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
