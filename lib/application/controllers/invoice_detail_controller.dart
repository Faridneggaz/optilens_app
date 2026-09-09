import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/invoice_detail_repository.dart';
import '../../domain/response/invoice_detail_response.dart';

class InvoiceDetailController extends GetxController {
  InvoiceDetailController({InvoiceDetailRepository? repo})
      : _repo = repo ?? Get.find<InvoiceDetailRepository>();

  final InvoiceDetailRepository _repo;

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
      final data        = await _repo.getInvoiceDetails(invoiceName: _invoiceName);
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