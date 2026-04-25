import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../application/controllers/stock_entry_details_controller.dart';
import '../../domain/response/stock_entry_item.dart' as model;
import '../../widgets/header.dart';

class StockEntryPage extends StatelessWidget {
  const StockEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller is registered by UserDashboardController.navigateToStockEntry
    // via BindingsBuilder before this page is pushed. Fallback to Get.put.
    final c = Get.put(StockEntryDetailsController());

    return Obx(() {
      if (c.isLoading.value) {
        return const Scaffold(
            body:
                Center(child: CircularProgressIndicator(color: Colors.teal)));
      }

      const headerStyle = TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black);
      final data = c.data.value;
      if (data == null) {
        return const Scaffold(
            body: Center(child: Text('Failed to load stock entry.')));
      }

      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 247, 255, 254),
        body: Column(children: [
          AppHeader(
              title: 'Stock Entry', customer: null, customerCode: ''),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(children: [
                Text('Date : ${data.stock_entry.posting_date}',
                    style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 12),
                Text('Company : ${data.stock_entry.company}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 20),

                if (data.stock_entry.from_warehouse.isNotEmpty)
                  _warehouseBox(
                    title:        'From',
                    value:        data.stock_entry.from_warehouse,
                    isValidated:  c.fromWarehouseValidated.value,
                    onTap: () => c.fromWarehouseValidated.value =
                        !c.fromWarehouseValidated.value,
                    isPending:    c.isPending,
                  ),
                const SizedBox(height: 12),

                if (data.stock_entry.to_warehouse.isNotEmpty)
                  _warehouseBox(
                    title:        'To',
                    value:        data.stock_entry.to_warehouse,
                    isValidated:  c.toWarehouseValidated.value,
                    onTap: () => c.toWarehouseValidated.value =
                        !c.toWarehouseValidated.value,
                    isPending:    c.isPending,
                  ),

                const SizedBox(height: 25),

                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  const Text('Items',
                      style: TextStyle(
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
                    const Expanded(
                        flex: 4,
                        child: Text('Item Name',
                            textAlign: TextAlign.left,
                            style: headerStyle)),
                    const Expanded(
                        flex: 2,
                        child: Text('QTY',
                            textAlign: TextAlign.center,
                            style: headerStyle)),
                    const Expanded(
                        flex: 2,
                        child: Text('Status',
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
                              item.item_code.isNotEmpty
                                  ? item.item_code
                                  : item.item_name,
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
                        : Text(c.isPending ? 'APPROVE' : 'APPROVED',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                  ),
                )),
          ),
        ]),
      );
    });
  }

  Future<void> _handleApprove(StockEntryDetailsController c) async {
    final result = await c.approveStockEntry();
    if (result['message'] == 'Success') {
      Get.snackbar(
        'Succès',
        result['detail'] ?? 'Stock Entry approved successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.back();
    } else {
      Get.snackbar(
        'Erreur',
        result['error'] ?? 'Failed to approve',
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
          scrollable: true,
          title: const Text('Add Item'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: searchCtrl,
                decoration: InputDecoration(
                  labelText: 'Search Item',
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
                decoration:   const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                controller:   TextEditingController(text: '1'),
                onChanged: (v) => qty = int.tryParse(v) ?? 1,
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedItemCode != null
                  ? () {
                      c.addItem(model.StockEntryItem(
                        id:             '',
                        idx:            c.data.value!.items.length + 1,
                        item_code:      selectedItemCode!,
                        item_name:      selectedItemName ?? selectedItemCode!,
                        from_warehouse: c.data.value!.stock_entry.from_warehouse,
                        to_warehouse:   c.data.value!.stock_entry.to_warehouse,
                        quantity:       qty,
                      ));
                      Get.back();
                    }
                  : null,
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}