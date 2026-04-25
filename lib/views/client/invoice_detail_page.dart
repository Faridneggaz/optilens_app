import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../application/controllers/invoice_detail_controller.dart';

class InvoiceDetailPage extends StatelessWidget {
  const InvoiceDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<InvoiceDetailController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('',
            style: TextStyle(
                color: Color(0xFF00A69C), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      floatingActionButton: Obx(() => FloatingActionButton(
            onPressed:
                (c.isLoading.value || c.error.value != null)
                    ? null
                    : _handlePrint(c),
            backgroundColor: const Color(0xFF00A69C),
            child: const Icon(Icons.print, color: Colors.white),
          )),

      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF00A69C)));
        }
        if (c.error.value != null) {
          return Center(child: Text(c.error.value!));
        }
        final inv = c.invoiceData.value!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invoice #${inv.invoice.name}',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Issued: ${inv.invoice.postingDate}',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 15)),

                const SizedBox(height: 30),
                const Text('Items',
                    style: TextStyle(
                        fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: inv.items.length,
                  itemBuilder: (context, index) {
                    final item = inv.items[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: Colors.grey.shade200))),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.itemName,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(
                                  'Qty: ${item.qty.toInt()}   Unit Price: ${item.rate.toStringAsFixed(2)} DA',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Text(
                              '${item.amount.toStringAsFixed(2)} DA',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 35),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('Total Amount: ',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Text(
                        '${inv.invoice.grandTotal.toStringAsFixed(2)} DA',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900)),
                  ],
                ),

                const SizedBox(height: 40),

                Center(
                  child: Text(
                    'Status: ${inv.invoice.status}',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: c.getStatusColor(inv.invoice.status)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Returns a callback: if already connected print directly, else show dialog.
  VoidCallback _handlePrint(InvoiceDetailController c) {
    return () async {
      if (c.connected.value) {
        final isConn = await c.bluetooth.isConnected;
        if (isConn == true) {
          c.printTicketSmall();
          return;
        } else {
          c.connected.value = false;
        }
      }
      _showDeviceDialog(c);
    };
  }

  void _showDeviceDialog(InvoiceDetailController c) async {
    final devices = await c.bluetooth.getBondedDevices();
    final printers = devices.where((d) {
      final name = (d.name ?? '').toLowerCase();
      return name.contains('pt') ||
          name.contains('mtp') ||
          name.contains('print') ||
          name.contains('pos') ||
          name.contains('goojprt');
    }).toList();
    final list = printers.isNotEmpty ? printers : devices;

    Get.dialog(AlertDialog(
      title: const Text("Choisir l'imprimante"),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: list.isEmpty
            ? const Center(
                child: Text('Aucune imprimante trouvée via Bluetooth.'))
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) => ListTile(
                  leading:
                      const Icon(Icons.print, color: Color(0xFF00A69C)),
                  title: Text(list[i].name ?? 'Inconnu'),
                  subtitle: Text(list[i].address ?? ''),
                  onTap: () {
                    Get.back();
                    c.connectAndPrint(list[i]);
                  },
                ),
              ),
      ),
    ));
  }
}