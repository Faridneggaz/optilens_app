import 'package:flutter/material.dart';
import '../../application/controllers/stock_entry_details_controller.dart';
import '../../domain/response/stock_entry_details_response.dart';
import '../../widgets/header.dart';

class StockEntryPage extends StatefulWidget {
  final String stockEntryName;
  final String token;

  const StockEntryPage({
    super.key,
    required this.stockEntryName,
    required this.token,
  });

  @override
  State<StockEntryPage> createState() => _StockEntryPageState();
}

class _StockEntryPageState extends State<StockEntryPage> {
  StockEntryDetailsResponse? data;
  bool loading = true;

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

    setState(() {
      data = result;
      loading = false;
    });
  }

  Widget statusBox({
    required String title,
    required String value,
    required bool confirmed,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: confirmed ? Colors.teal : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          if (!confirmed)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          if (!confirmed) const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? "-" : value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (confirmed) const Icon(Icons.check_circle, color: Colors.black),
        ],
      ),
    );
  }

  Widget itemRow({required String name, required int quantity}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(name)),
          Expanded(
            flex: 2,
            child: Text(quantity.toString(), textAlign: TextAlign.center),
          ),
          const Expanded(
            flex: 2,
            child: Icon(Icons.check_circle, color: Colors.teal),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 255, 254),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : data == null
          ? const Center(child: Text("Failed to load data"))
          : Column(
              children: [
                AppHeader(
                  title: 'Stock Entry',
                  customer: null,
                  customerCode: '',
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListView(
                      children: [
                        Text(
                          'Date : ${data!.stock_entry.posting_date}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Company : ${data!.stock_entry.company}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        statusBox(
                          title: 'From',
                          value: data!.stock_entry.from_warehouse,
                          confirmed:
                              data!.stock_entry.from_warehouse.isNotEmpty,
                        ),
                        const SizedBox(height: 12),
                        statusBox(
                          title: 'To',
                          value: data!.stock_entry.to_warehouse,
                          confirmed: data!.stock_entry.to_warehouse.isNotEmpty,
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: const [
                            Expanded(flex: 4, child: Text('Item Name')),
                            Expanded(
                              flex: 2,
                              child: Text('Qty', textAlign: TextAlign.center),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Status',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        ...data!.items.map(
                          (item) => itemRow(
                            name: item.item_name,
                            quantity: item.quantity,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.teal,
                      ),
                      child: const Text(
                        'DONE',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
