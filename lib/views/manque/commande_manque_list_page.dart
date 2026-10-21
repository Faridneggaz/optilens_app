import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../presentation/controllers/commande_manque_controller.dart';
import '../../presentation/controllers/language_controller.dart';
import '../../widgets/header.dart';
import '../../widgets/manque/manque_widgets.dart';
import '../../widgets/stock/document_ui.dart';

class CommandeManqueListPage extends StatefulWidget {
  const CommandeManqueListPage({super.key});

  @override
  State<CommandeManqueListPage> createState() => _CommandeManqueListPageState();
}

class _CommandeManqueListPageState extends State<CommandeManqueListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<CommandeManqueController>()) {
        Get.find<CommandeManqueController>().onRefresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CommandeManqueController>();

    return GetBuilder<LanguageController>(
      builder: (_) => Scaffold(
        backgroundColor: AppColors.scaffold,
        floatingActionButton: Obx(() {
          if (!c.canCreate.value) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: c.openForm,
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              'manque_new_commande'.tr,
              style: const TextStyle(color: Colors.white),
            ),
          );
        }),
        body: Column(
          children: [
            AppHeader(
              title: 'manque_commandes_title'.tr,
              customer: null,
              customerCode: '',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: c.searchController,
                        onChanged: (v) => c.searchQuery.value = v,
                        decoration: InputDecoration(
                          hintText: 'manque_search_hint'.tr,
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Obx(() => ManqueFilterChips(
                  values: c.statusFilters,
                  selected: c.selectedStatus.value,
                  labelOf: c.statusLabel,
                  onSelected: (v) => c.selectedStatus.value = v,
                )),
            const SizedBox(height: 8),
            Expanded(
              child: Obx(() {
                if (c.isLoading.value && c.items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (c.displayList.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: c.onRefresh,
                    color: AppColors.primary,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.28),
                        Center(
                          child: Text(
                            'manque_no_commandes'.tr,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: c.onRefresh,
                  color: AppColors.primary,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 88),
                    itemCount: c.displayList.length + 1,
                    itemBuilder: (context, index) {
                      if (index == c.displayList.length) {
                        return DocumentLoadMoreFooter(
                          hasMore: c.hasMore.value,
                          isLoadingMore: c.isLoadingMore.value,
                          hasItems: c.items.isNotEmpty,
                          isSearching: c.searchQuery.value.isNotEmpty,
                          onLoadMore: c.onLoadMore,
                        );
                      }
                      final cmd = c.displayList[index];
                      return CommandeManqueCard(
                        commande: cmd,
                        onTap: () => c.openDetail(cmd),
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
