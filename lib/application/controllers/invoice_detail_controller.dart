import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/repositories/invoice_detail_repository.dart';
import '../../domain/response/invoice_detail_response.dart';

class InvoiceDetailController extends GetxController {
  final _repo     = InvoiceDetailRepository();
  final bluetooth = BlueThermalPrinter.instance;

  // Data state
  final invoiceData = Rxn<InvoiceDetailResponse>();
  final isLoading   = true.obs;
  final error       = Rxn<String>();

  // Bluetooth state
  final devices         = <BluetoothDevice>[].obs;
  final connected       = false.obs;
  final selectedDevice  = Rxn<BluetoothDevice>();

  String _invoiceName = '';

  @override
  void onInit() {
    super.onInit();
    final args   = Get.arguments as Map<String, dynamic>?;
    _invoiceName = args?['invoiceName'] as String? ?? '';
    loadInvoiceDetails();
    initBluetooth();
  }

  Future<void> loadInvoiceDetails() async {
    isLoading.value = true;
    error.value     = null;
    try {
      final data        = await _repo.getInvoiceDetails(invoiceName: _invoiceName);
      invoiceData.value = data;
    } catch (e) {
      error.value = 'Impossible de charger les détails: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> initBluetooth() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    try {
      final devs      = await bluetooth.getBondedDevices();
      final isConn    = await bluetooth.isConnected;
      devices.value   = devs;
      connected.value = isConn ?? false;
    } catch (_) {}
  }

  Future<void> connectAndPrint(BluetoothDevice device) async {
    Get.snackbar('Bluetooth', 'Connexion à ${device.name}...');
    try {
      if (await bluetooth.isConnected == true) await bluetooth.disconnect();
      await bluetooth.connect(device);
      connected.value      = true;
      selectedDevice.value = device;
      await printTicketSmall();
    } catch (e) {
      if (e.toString().contains('already connected')) {
        connected.value      = true;
        selectedDevice.value = device;
        await printTicketSmall();
      } else {
        Get.snackbar('Erreur Bluetooth', e.toString(),
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  Future<void> printTicketSmall() async {
    if (invoiceData.value == null) return;
    final inv      = invoiceData.value!.invoice;
    final items    = invoiceData.value!.items;
    final totalQty = items.fold<double>(0, (s, i) => s + i.qty);

    Uint8List? logoBytes;
    try {
      final data = await rootBundle.load('assets/images/optilensss.png');
      logoBytes  = data.buffer.asUint8List();
    } catch (_) {}

    final isConn = await bluetooth.isConnected;
    if (isConn != true) return;

    if (logoBytes != null) bluetooth.printImageBytes(logoBytes);
    bluetooth.printNewLine();
    bluetooth.printCustom('OPTILENS ALGER', 2, 1);
    bluetooth.printNewLine();
    bluetooth.printCustom('--------------------------------', 1, 1);
    bluetooth.printCustom('Client: ${inv.customer ?? 'Passage'}', 1, 0);
    bluetooth.printCustom('Cmd: ${inv.name}', 1, 0);
    bluetooth.printCustom('Date: ${inv.postingDate}', 1, 0);
    bluetooth.printCustom('--------------------------------', 1, 1);

    final header =
        'Art'.padRight(12) + 'Qt'.padLeft(3) + 'Px'.padLeft(7) + 'Tot'.padLeft(9);
    bluetooth.printCustom(header, 1, 0);

    for (final item in items) {
      final name  = item.itemName.length > 12
          ? item.itemName.substring(0, 12)
          : item.itemName.padRight(12);
      final qty   = item.qty.toInt().toString().padLeft(3);
      final price = item.rate.toStringAsFixed(0).padLeft(7);
      final total = item.amount.toStringAsFixed(0).padLeft(9);
      bluetooth.printCustom('$name$qty$price$total', 0, 0);
    }

    bluetooth.printCustom('--------------------------------', 1, 1);
    bluetooth.printLeftRight('Qte Totale:', totalQty.toInt().toString(), 1);
    bluetooth.printNewLine();
    bluetooth.printCustom('Total: ${inv.grandTotal.toStringAsFixed(0)} DA', 2, 1);
    bluetooth.printNewLine();
    bluetooth.printCustom('Merci de votre visite!', 1, 1);
    bluetooth.printNewLine();
    bluetooth.printNewLine();
    bluetooth.printNewLine();
  }

  Color getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('paid'))   return Colors.green;
    if (s.contains('unpaid')) return Colors.red;
    return Colors.orange;
  }
}