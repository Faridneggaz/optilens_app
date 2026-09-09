import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../presentation/controllers/stock_entry_details_controller.dart';
import '../../domain/entities/stock_entry_item.dart' as model;
import '../../widgets/header.dart';
import '../../../presentation/controllers/language_controller.dart';
import '../../core/theme/app_colors.dart';

class StockEntryPage extends StatelessWidget {
  const StockEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<StockEntryDetailsController>();

    return GetBuilder<LanguageController>(
      builder: (_) => Obx(() {
      if (c.isLoading.value) {
        return const Scaffold(
            body:
                Center(child: CircularProgressIndicator(color: Colors.teal)));
      }

      const headerStyle = TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black);
      final data = c.data.value;
      if (data == null) {
        return Scaffold(
            body: Center(child: Text('failed_load_stock'.tr)));
      }

      return Scaffold(
        backgroundColor: AppColors.scaffoldTint,
        body: Column(children: [
          AppHeader(
              title: 'stock_entry_page_title'.tr, customer: null, customerCode: ''),

          Expanded(
            child: RefreshIndicator(
              onRefresh: c.onRefresh,
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                Text('${'date_label_stock'.tr}${data.stockEntry.postingDate}',
                    style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 12),
                Text('${'company_label'.tr}${data.stockEntry.company}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 20),

                if (data.stockEntry.fromWarehouse.isNotEmpty)
                  _warehouseBox(
                    title:        'warehouse_from'.tr,
                    value:        data.stockEntry.fromWarehouse,
                    isValidated:  c.fromWarehouseValidated.value,
                    onTap: () => c.fromWarehouseValidated.value =
                        !c.fromWarehouseValidated.value,
                    isPending:    c.isPending,
                  ),
                const SizedBox(height: 12),

                if (data.stockEntry.toWarehouse.isNotEmpty)
                  _warehouseBox(
                    title:        'warehouse_to'.tr,
                    value:        data.stockEntry.toWarehouse,
                    isValidated:  c.toWarehouseValidated.value,
                    onTap: () => c.toWarehouseValidated.value =
                        !c.toWarehouseValidated.value,
                    isPending:    c.isPending,
                  ),

                const SizedBox(height: 25),

                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  Text('items_label'.tr,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  if (c.isPending)
                    IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: Colors.teal, size: 28),
                        onPressed: () => _showAddItemDialog(context, c)),
                ]),

                const SizedBox(height: 15),

                // Column headers
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Row(children: [
                    if (c.isPending) const SizedBox(width: 40),
                    Expanded(
                        flex: 4,
                        child: Text('item_name'.tr,
                            textAlign: TextAlign.left,
                            style: headerStyle)),
                    Expanded(
                        flex: 2,
                        child: Text('qty_header'.tr,
                            textAlign: TextAlign.center,
                            style: headerStyle)),
                    Expanded(
                        flex: 2,
                        child: Text('status_header'.tr,
                            textAlign: TextAlign.center,
                            style: headerStyle)),
                  ]),
                ),
                const Divider(thickness: 1.0, color: Colors.black26),

                ...data.items.asMap().entries.map((entry) {
                  final idx  = entry.key;
                  final item = entry.value;
                  final isValidated =
                      c.validatedItemIndices.contains(idx);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      if (c.isPending)
                        SizedBox(
                          width: 40,
                          child: !isValidated
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red, size: 20),
                                  onPressed: () => c.removeItem(idx),
                                )
                              : const SizedBox(),
                        ),

                      Expanded(
                          flex: 4,
                          child: Text(
                              item.itemCode.isNotEmpty
                                  ? item.itemCode
                                  : item.itemName,
                              style: const TextStyle(fontSize: 14))),

                      Expanded(
                          flex: 2,
                          child: (isValidated || !c.isPending)
                              ? Text(item.quantity.toString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))
                              : TextFormField(
                                  initialValue: item.quantity.toString(),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold),
                                  onChanged: (v) =>
                                      item.quantity = int.tryParse(v) ??
                                          item.quantity,
                                )),

                      Expanded(
                          flex: 2,
                          child: IconButton(
                            icon: Icon(Icons.check_circle,
                                color: isValidated
                                    ? Colors.teal
                                    : Colors.grey),
                            onPressed: c.isPending
                                ? () => c.toggleItemValidation(idx)
                                : null,
                          )),
                    ]),
                  );
                }),
                  ]),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (c.canApprove && !c.isSubmitting.value)
                        ? () => _handleApprove(c)
                        : (c.isPending ? null : Get.back),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: (c.isPending && !c.canApprove)
                          ? Colors.grey.shade400
                          : Colors.teal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: c.isSubmitting.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(c.isPending ? 'btn_approve'.tr : 'btn_approved'.tr,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                  ),
                )),
          ),
        ]),
      );
    }));
  }

  Future<void> _handleApprove(StockEntryDetailsController c) async {
        final result = await c.approveStockEntry();
    if (result.isAuthHandled) {
      return;
    }
    if (result.isSuccess) {
      Get.snackbar(
        'success'.tr,
        result.detail ?? 'approve_success'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.back();
    } else {
      Get.snackbar(
        'error'.tr,
        result.error ?? 'approve_error'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _warehouseBox({
    required String title,
    required String value,
    required bool isValidated,
    required VoidCallback onTap,
    required bool isPending,
  }) {
    return GestureDetector(
      onTap: isPending ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        isValidated ? Colors.teal : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 12,
                      color: isValidated
                          ? Colors.white70
                          : Colors.black54)),
              Text(value,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isValidated
                          ? Colors.white
                          : Colors.black87)),
            ]),
          ),
          Icon(Icons.check_circle,
              color: isValidated ? Colors.white : Colors.grey.shade500),
        ]),
      ),
    );
  }

  void _showAddItemDialog(
      BuildContext context, StockEntryDetailsController c) async {
    String? selectedItemCode;
    String? selectedItemName;
    int qty = 1;
    List<Map<String, String>> searchResults = [];
    bool isSearching = false;
    final searchCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: AppColors.scaffold,
          scrollable: true,
          title: Text('add_item_dialog_title'.tr),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: searchCtrl,
                decoration: InputDecoration(
                  labelText: 'search_item_label'.tr,
                  suffixIcon: isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.search),
                ),
                onChanged: (val) async {
                  if (val.isEmpty) {
                    setD(() => searchResults = []);
                    return;
                  }
                  setD(() => isSearching = true);
                  final results = await c.searchItems(val);
                  setD(() {
                    searchResults = results;
                    isSearching   = false;
                  });
                },
              ),

              const SizedBox(height: 10),

              if (searchResults.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: searchResults.map((item) => ListTile(
                            title: Text(item['item_code'] ?? ''),
                            onTap: () => setD(() {
                              selectedItemCode = item['item_code'];
                              selectedItemName = item['item_code'];
                              searchCtrl.text  = item['item_code'] ?? '';
                              searchResults    = [];
                            }),
                          )).toList(),
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              TextField(
                decoration: InputDecoration(labelText: 'quantity_label'.tr),
                keyboardType: TextInputType.number,
                controller:   TextEditingController(text: '1'),
                onChanged: (v) => qty = int.tryParse(v) ?? 1,
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Get.back(),
                child: Text('btn_cancel'.tr)),
            ElevatedButton(
              onPressed: selectedItemCode != null
                  ? () {
                      c.addItem(model.StockEntryItem(
                        id:            '',
                        idx:           c.data.value!.items.length + 1,
                        itemCode:      selectedItemCode!,
                        itemName:      selectedItemName ?? selectedItemCode!,
                        fromWarehouse: c.data.value!.stockEntry.fromWarehouse,
                        toWarehouse:   c.data.value!.stockEntry.toWarehouse,
                        quantity:      qty,
                      ));
                      Get.back();
                    }
                  : null,
              child: Text('btn_add'.tr),
            ),
          ],
        ),
      ),
    );
  }
}