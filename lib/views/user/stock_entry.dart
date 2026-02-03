import 'package:flutter/material.dart';
import 'dart:convert';
import '../../application/controllers/stock_entry_details_controller.dart';
import '../../domain/response/stock_entry_details_response.dart';
import '../../domain/response/stock_entry_item.dart' as model; 
import '../../widgets/header.dart';

class StockEntryPage extends StatefulWidget {
  final String stockEntryName;
  final String token;

  const StockEntryPage({super.key, required this.stockEntryName, required this.token});

  @override
  State<StockEntryPage> createState() => _StockEntryPageState();
}

class _StockEntryPageState extends State<StockEntryPage> {
  StockEntryDetailsResponse? data;
  bool loading = true;
  bool isSubmitting = false;

  bool fromWarehouseValidated = false;
  bool toWarehouseValidated = false;
  Set<int> validatedItemIndices = {};

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final result = await StockEntryDetailsController().fetchDetails(
      name: widget.stockEntryName,
      token: widget.token,
    );
    if (mounted) {
      setState(() {
        data = result;
        loading = false;
        if (!isPending && data != null) {
          fromWarehouseValidated = true;
          toWarehouseValidated = true;
          validatedItemIndices = Set.from(List.generate(data!.items.length, (i) => i));
        }
      });
    }
  }

  bool get isPending {
    if (data == null) return false;
    String status = data!.stock_entry.status.toLowerCase();
    return status == "pending" || status == "draft";
  }

  bool get canApprove {
    if (!isPending) return false;
    bool itemsReady = (data != null) && (validatedItemIndices.length == data!.items.length);
    bool warehousesReady = true;
    if (data?.stock_entry.from_warehouse.isNotEmpty ?? false) warehousesReady = warehousesReady && fromWarehouseValidated;
    if (data?.stock_entry.to_warehouse.isNotEmpty ?? false) warehousesReady = warehousesReady && toWarehouseValidated;
    return itemsReady && warehousesReady;
  }

  void _addNewItem() {
    String code = "";
    int qty = 1;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: "Item Code"), onChanged: (val) => code = val),
            TextField(decoration: const InputDecoration(labelText: "Quantity"), keyboardType: TextInputType.number, onChanged: (val) => qty = int.tryParse(val) ?? 1),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (code.isNotEmpty) {
                setState(() {
                  data!.items.add(model.StockEntryItem(
                    id: "", 
                    idx: data!.items.length + 1, 
                    item_code: code, 
                    item_name: code, 
                    from_warehouse: data!.stock_entry.from_warehouse, 
                    to_warehouse: data!.stock_entry.to_warehouse, 
                    quantity: qty
                  ));
                });
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  Future<void> handleApprove() async {
    setState(() => isSubmitting = true);
    String itemsJson = jsonEncode(data!.items.map((e) => e.toJson()).toList());
    final success = await StockEntryDetailsController().manageStockEntry(
      token: widget.token, name: widget.stockEntryName, items: itemsJson, action: "approve",
    );
    if (success && mounted) { Navigator.pop(context); } 
    else { setState(() => isSubmitting = false); }
  }

  Widget warehouseBox({required String title, required String value, required bool isValidated, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: isPending ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isValidated ? Colors.teal : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 12, color: isValidated ? Colors.white70 : Colors.black54)),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isValidated ? Colors.white : Colors.black87)),
            ])),
            Icon(Icons.check_circle, color: isValidated ? Colors.white : Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.teal)));
    

    const headerStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 255, 254),
      body: Column(
        children: [
          AppHeader(title: 'Stock Entry', customer: null, customerCode: ''),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Text('Date : ${data!.stock_entry.posting_date}', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  Text('Company : ${data!.stock_entry.company}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20),
                  if (data!.stock_entry.from_warehouse.isNotEmpty) warehouseBox(title: 'From', value: data!.stock_entry.from_warehouse, isValidated: fromWarehouseValidated, onTap: () => setState(() => fromWarehouseValidated = !fromWarehouseValidated)),
                  const SizedBox(height: 12),
                  if (data!.stock_entry.to_warehouse.isNotEmpty) warehouseBox(title: 'To', value: data!.stock_entry.to_warehouse, isValidated: toWarehouseValidated, onTap: () => setState(() => toWarehouseValidated = !toWarehouseValidated)),
                  
                  const SizedBox(height: 25),
                  
                  // Section Titre "Items" principal
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Items', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (isPending) IconButton(icon: const Icon(Icons.add_circle, color: Colors.teal, size: 28), onPressed: _addNewItem),
                  ]),
                  
                  const SizedBox(height: 15),
                  
                  
                  // Section Titre "Items" principal
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Items', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (isPending) IconButton(icon: const Icon(Icons.add_circle, color: Colors.teal, size: 28), onPressed: _addNewItem),
                  ]),
                  
                  const SizedBox(height: 15),
                  
                  // EN-TÊTES DE COLONNES CORRIGÉS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.0), // On enlève le padding pour coller au bord
                    child: Row(
                      children: [
                        // Cet espace vide de 40px est CRUCIAL pour l'alignement 
                        // Il simule la place de l'icône poubelle rouge 
                        if (isPending) const SizedBox(width: 40), 
                        
                        const Expanded(
                          flex: 4, 
                          child: Text(
                            'Item Name', 
                            textAlign: TextAlign.left, // Aligné à gauche
                            style: headerStyle,
                          )
                        ),
                        const Expanded(
                          flex: 2, 
                          child: Text(
                            'QTY', 
                            textAlign: TextAlign.center, 
                            style: headerStyle,
                          )
                        ),
                        const Expanded(
                          flex: 2, 
                          child: Text(
                            'Status', 
                            textAlign: TextAlign.center, 
                            style: headerStyle,
                          )
                        ),
                      ],
                    ),
                  ),
                  const Divider(thickness: 1.0, color: Colors.black26),
                  const Divider(thickness: 1.0, color: Colors.black26),
                  
                  ...data!.items.asMap().entries.map((entry) {
                    int index = entry.key;
                    var item = entry.value;
                    bool isValidated = validatedItemIndices.contains(index);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          if (isPending) 
                            SizedBox(
                              width: 40,
                              child: !isValidated 
                                ? IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () => setState(() {
                                      data!.items.removeAt(index);
                                      validatedItemIndices = validatedItemIndices
                                          .where((i) => i != index)
                                          .map((i) => i > index ? i - 1 : i)
                                          .toSet();
                                    }),
                                  )
                                : const SizedBox(), 
                            ),

                          Expanded(flex: 4, child: Text(item.item_name, style: const TextStyle(fontSize: 14))),
                          Expanded(
                            flex: 2, 
                            child: (isValidated || !isPending) 
                              ? Text(item.quantity.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)) 
                              : TextFormField(
                                  initialValue: item.quantity.toString(), 
                                  keyboardType: TextInputType.number, 
                                  textAlign: TextAlign.center, 
                                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                                  onChanged: (val) => item.quantity = int.tryParse(val) ?? item.quantity,
                                )
                          ),
                          Expanded(
                            flex: 2, 
                            child: IconButton(
                              icon: Icon(Icons.check_circle, color: isValidated ? Colors.teal : Colors.grey), 
                              onPressed: isPending ? () => setState(() { 
                                if (isValidated) validatedItemIndices.remove(index); 
                                else validatedItemIndices.add(index); 
                              }) : null
                            )
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (canApprove && !isSubmitting) ? handleApprove : (isPending ? null : () => Navigator.pop(context)),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: (isPending && !canApprove) ? Colors.grey.shade400 : Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: isSubmitting ? const CircularProgressIndicator(color: Colors.white) : Text(isPending ? 'APPROVE' : 'DONE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}