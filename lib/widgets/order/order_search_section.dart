import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/item.dart';
import '../../presentation/controllers/order_controller.dart';
import 'order_suggestion_tile.dart';

class OrderSearchSection extends StatelessWidget {
  const OrderSearchSection({super.key, required this.controller});

  final OrderController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 8),
      child: SearchAnchor(
        viewBackgroundColor: AppColors.scaffold,
        viewSurfaceTintColor: Colors.transparent,
        viewElevation: 0,
        viewShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
        builder: (context, searchController) => SearchBar(
          controller: searchController,
          hintText: 'search_item_bar_hint'.tr,
          onTap: () => searchController.openView(),
          onChanged: (_) => searchController.openView(),
          leading: const Icon(Icons.search, color: AppColors.primaryDark),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStatePropertyAll(
            AppColors.primaryDark.withValues(alpha: 0.05),
          ),
        ),
        suggestionsBuilder: (context, searchController) async {
          final q = searchController.text.trim();
          if (q.isEmpty) {
            return [
              ListTile(
                leading: const Icon(Icons.search, color: Colors.grey),
                title: Text('search_item_hint'.tr),
              )
            ];
          }
          final results = await controller.searchItems(q);
          if (results.isEmpty) {
            return [
              ListTile(
                leading:
                    const Icon(Icons.info_outline, color: Colors.orange),
                title: Text('no_item_found'.tr),
              )
            ];
          }
          return results
              .map((Item item) => OrderSuggestionTile(
                    controller: controller,
                    item: item,
                    searchController: searchController,
                  ))
              .toList();
        },
      ),
    );
  }
}
