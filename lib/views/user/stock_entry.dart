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

  void _addNewItem() async {
    String? selectedItemCode;
    String? selectedItemName;
    int qty = 1;
    List<Map<String, String>> searchResults = [];
    bool isSearching = false;
    TextEditingController searchController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Add Item"),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Champ de recherche
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: "Search Item",
                      suffixIcon: isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                    ),
                    onChanged: (val) async {
                      if (val.isEmpty) {
                        setDialogState(() {
                          searchResults = [];
                        });
                        return;
                      }

                      setDialogState(() {
                        isSearching = true;
                      });

                      final results = await StockEntryDetailsController().searchItems(
                        token: widget.token,
                        searchText: val,
                      );

                      setDialogState(() {
                        searchResults = results;
                        isSearching = false;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 10),

                  // Liste des résultats
                  if (searchResults.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final item = searchResults[index];
                          return ListTile(
                            title: Text(item['item_name'] ?? ''),
                            subtitle: Text(item['item_code'] ?? ''),
                            onTap: () {
                              setDialogState(() {
                                selectedItemCode = item['item_code'];
                                selectedItemName = item['item_name'];
                                searchController.text = item['item_name'] ?? '';
                                searchResults = [];
                              });
                            },
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Champ quantité
                  TextField(
                    decoration: const InputDecoration(labelText: "Quantity"),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => qty = int.tryParse(val) ?? 1,
                    controller: TextEditingController(text: '1'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: selectedItemCode != null
                    ? () {
                        setState(() {
                          data!.items.add(model.StockEntryItem(
                            id: "",
                            idx: data!.items.length + 1,
                            item_code: selectedItemCode!,
                            item_name: selectedItemName ?? selectedItemCode!,
                            from_warehouse: data!.stock_entry.from_warehouse,
                            to_warehouse: data!.stock_entry.to_warehouse,
                            quantity: qty,
                          ));
                        });
                        Navigator.pop(context);
                      }
                    : null,
                child: const Text("Add"),
              )
            ],
          );
        },
      ),
    );
  }

  // ✅ FONCTION D'APPROBATION CORRIGÉE
  Future<void> handleApprove() async {
    setState(() => isSubmitting = true);

    // Préparer les items au bon format
    final itemsToSend = data!.items.map((e) => {
      "itemName": e.item_code,
      "quantity": e.quantity,
      "fromWarehouse": e.from_warehouse,
      "toWarehouse": e.to_warehouse,
    }).toList();

    // Utiliser la nouvelle méthode approveStockEntry
    final result = await StockEntryDetailsController().approveStockEntry(
      name: widget.stockEntryName,
      token: widget.token,
      items: itemsToSend,
      action: "approve",
    );

    if (!mounted) return;

    if (result["message"] == "Success") {
      // Succès - retour à la page précédente
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["detail"] ?? "Stock Entry approved successfully"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      // Erreur - afficher le message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["error"] ?? "Failed to approve"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => isSubmitting = false);
    }
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
                  
                  // EN-TÊTES DE COLONNES
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.0),
                    child: Row(
                      children: [
                        if (isPending) const SizedBox(width: 40), 
                        
                        const Expanded(
                          flex: 4, 
                          child: Text(
                            'Item Name', 
                            textAlign: TextAlign.left,
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
                child: isSubmitting ? const CircularProgressIndicator(color: Colors.white) : Text(isPending ? 'APPROVE' : 'APPROVED', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}