import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../application/controllers/invoice_detail_controller.dart';
import '../../domain/response/invoice_detail_response.dart';

class InvoiceDetailPage extends StatefulWidget {
  final String invoiceName;
  final String invoiceType;

  const InvoiceDetailPage({
    super.key,
    required this.invoiceName,
    this.invoiceType = "Sales Invoice",
  });

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  final InvoiceDetailController _controller = InvoiceDetailController();
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  InvoiceDetailResponse? _invoiceData;
  bool _isLoading = true;
  String? _error;

  List<BluetoothDevice> _devices = [];
  bool _connected = false;
  BluetoothDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _loadInvoiceDetails();
    _initBluetooth();
  }

// --- LOGIQUE BLUETOOTH ---
  Future<void> _initBluetooth() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    try {
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
      // On vérifie si on est déjà connecté au démarrage
      bool? isConnected = await bluetooth.isConnected;
      
      if (mounted) {
        setState(() {
          _devices = devices;
          _connected = isConnected ?? false;
        });
      }
    } catch (e) {
      print("Erreur Bluetooth: $e");
    }
  }

  Future<void> _loadInvoiceDetails() async {
    setState(() => _isLoading = true);
    try {
      final data = await _controller.getInvoiceDetails(invoiceName: widget.invoiceName);
      setState(() {
        _invoiceData = data;
        _isLoading = false;
        if (data == null) _error = 'Impossible de charger les détails';
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur : $e';
        _isLoading = false;
      });
    }
  }


  void _handlePrintButton() async {
  
    if (_connected) {
      bool? isConnected = await bluetooth.isConnected;
      if (isConnected == true) {

        _printTicketSmall(); 
        return;
      } else {

        setState(() => _connected = false);
      }
    }
    _showDeviceSelectionDialog();
  }

  void _showDeviceSelectionDialog() async {
    List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
    
    List<BluetoothDevice> printers = devices.where((d) {
      String name = (d.name ?? "").toLowerCase();
      return name.contains("pt") || name.contains("mtp") || name.contains("print") || name.contains("pos") || name.contains("goojprt");
    }).toList();

    List<BluetoothDevice> listToShow = printers.isNotEmpty ? printers : devices;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Choisir l'imprimante"),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: listToShow.isEmpty 
                ? const Center(child: Text("Aucune imprimante trouvée via Bluetooth."))
                : ListView.builder(
                    itemCount: listToShow.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.print, color: Color(0xFF00A69C)),
                        title: Text(listToShow[index].name ?? "Inconnu"),
                        subtitle: Text(listToShow[index].address ?? ""),
                        onTap: () {
                          Navigator.pop(context);
                          _connectAndPrint(listToShow[index]);
                        },
                      );
                    },
                  ),
          ),
        );
      },
    );
  }


  Future<void> _connectAndPrint(BluetoothDevice device) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connexion à ${device.name}...")));
    
    try {
   
      if (await bluetooth.isConnected == true) {
        await bluetooth.disconnect();
      }
      await bluetooth.connect(device);
      
      setState(() {
        _connected = true;
        _selectedDevice = device;
      });


      _printTicketSmall();

    } catch (e) {
      if (e.toString().contains("already connected")) {
         setState(() {
           _connected = true;
           _selectedDevice = device;
         });
         _printTicketSmall();
      } else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _printTicketSmall() async {
    if (_invoiceData == null) return;

    final inv = _invoiceData!.invoice;
    final items = _invoiceData!.items;
    final double totalQty = items.fold(0, (sum, item) => sum + item.qty);

    Uint8List? logoBytes;
    try {
      final ByteData data = await rootBundle.load('assets/images/optilensss.png');
      logoBytes = data.buffer.asUint8List();
    } catch (e) {
      print("Erreur logo: $e");
    }

    bluetooth.isConnected.then((isConnected) {
      if (isConnected == true) {
        // Logo
        if (logoBytes != null) bluetooth.printImageBytes(logoBytes);
        bluetooth.printNewLine();
 
       
        // En-tête        bluetooth.printCustom("OPTILENS ALGER", 2, 1);
        bluetooth.printNewLine();
        bluetooth.printCustom("--------------------------------", 1, 1);

        // Infos
        bluetooth.printCustom("Client: ${inv.customer ?? 'Passage'}", 1, 0);
        bluetooth.printCustom("Cmd: ${inv.name}", 1, 0);
        bluetooth.printCustom("Date: ${inv.postingDate}", 1, 0);
        bluetooth.printCustom("--------------------------------", 1, 1);

        // Tableau (Formaté pour 32 caractères max sur 58mm)
        String header = "Art".padRight(12) + "Qt".padLeft(3) + "Px".padLeft(7) + "Tot".padLeft(9);
        bluetooth.printCustom(header, 1, 0);

        for (var item in items) {
          String name = item.itemName.length > 12 
              ? item.itemName.substring(0, 12) 
              : item.itemName.padRight(12);
          String qty = item.qty.toInt().toString().padLeft(3);
          String price = item.rate.toStringAsFixed(0).padLeft(7);
          String total = item.amount.toStringAsFixed(0).padLeft(9);
          
          bluetooth.printCustom("$name$qty$price$total", 0, 0);
        }

        bluetooth.printCustom("--------------------------------", 1, 1);
        
        // Totaux
        bluetooth.printLeftRight("Qte Totale:", totalQty.toInt().toString(), 1);
        bluetooth.printNewLine();
        bluetooth.printCustom("Total: ${inv.grandTotal.toStringAsFixed(0)} DA", 2, 1);
        bluetooth.printNewLine();
        
        bluetooth.printCustom("Merci de votre visite!", 1, 1);
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printNewLine(); // Marge bas
      }
    });
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('paid')) return Colors.green;
    if (s.contains('unpaid')) return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "",
          style: TextStyle(color: Color(0xFF00A69C), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      
      
      floatingActionButton: FloatingActionButton(
        onPressed: (_isLoading || _error != null) ? null : _handlePrintButton,
        backgroundColor: const Color(0xFF00A69C),
        child: const Icon(Icons.print, color: Colors.white),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A69C)))
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre & Date
                        Text("Invoice #${_invoiceData!.invoice.name}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text("Issued: ${_invoiceData!.invoice.postingDate}", style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),

                        const SizedBox(height: 30),
                        const Text("Items", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),

                        // Liste des articles
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _invoiceData!.items.length,
                          itemBuilder: (context, index) {
                            final item = _invoiceData!.items[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.itemName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Text("Qty: ${item.qty.toInt()}   Unit Price: ${item.rate.toStringAsFixed(2)} DA", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Text("${item.amount.toStringAsFixed(2)} DA", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 35),

                        // Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text("Total Amount: ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 10),
                            Text("${_invoiceData!.invoice.grandTotal.toStringAsFixed(2)} DA", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // Statut
                        Center(
                          child: Text(
                            "Status: ${_invoiceData!.invoice.status}",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _getStatusColor(_invoiceData!.invoice.status)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }
}