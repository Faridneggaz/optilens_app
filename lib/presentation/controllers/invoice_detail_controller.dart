import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/invoice_detail_response.dart';
import '../../domain/usecases/usecases.dart';

class InvoiceDetailController extends GetxController {
  InvoiceDetailController({InvoiceUseCases? invoices})
      : _invoices = invoices ?? Get.find<InvoiceUseCases>();

  final InvoiceUseCases _invoices;

  // Data state
  final invoiceData = Rxn<InvoiceDetailResponse>();
  final isLoading   = true.obs;
  final error       = Rxn<String>();

  String _invoiceName = '';

  @override
  void onInit() {
    super.onInit();
    final data = Get.arguments;
    if (data != null && data is Map<String, dynamic>) {
      _invoiceName = data['invoiceName'] as String? ?? '';
    }
    loadInvoiceDetails();
  }

  Future<void> loadInvoiceDetails() async {
    isLoading.value = true;
    error.value     = null;
    try {
      final data        = await _invoices.getInvoiceDetails(_invoiceName);
      invoiceData.value = data;
    } catch (e) {
      error.value = '${'invoice_load_error'.tr}: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Color getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('paid'))   return Colors.green;
    if (s.contains('unpaid')) return Colors.red;
    return Colors.orange;
  }
}