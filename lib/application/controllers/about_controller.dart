import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/lead_repository.dart';
import '../../data/repositories/complaint_joptic_repository.dart';

class AboutController extends GetxController {
  final LeadRepository _leadRepository = LeadRepository();
  final ComplaintRepository _complaintRepository = ComplaintRepository();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final complaintClientController = TextEditingController();
  final complaintDescController = TextEditingController();
  
  var isLoading = false.obs;
  var isSubmittingComplaint = false.obs;

  Future<void> submitLead() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      Get.snackbar('required_fields'.tr, 'fill_all_fields'.tr);
      return;
    }

    isLoading.value = true;
    try {
      final response = await _leadRepository.createLead(name: name, phone: phone);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back();
        Get.snackbar('success'.tr, 'request_received'.tr);
        nameController.clear();
        phoneController.clear();
      } else {
        Get.snackbar('error'.tr, 'server_error'.tr);
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'erp_connection_error'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitComplaint() async {
    final clientName = complaintClientController.text.trim();
    final desc = complaintDescController.text.trim();

    if (clientName.isEmpty || desc.isEmpty) {
      Get.snackbar('error'.tr, 'fill_all_fields'.tr);
      return;
    }

    isSubmittingComplaint.value = true;
    try {
      final response = await _complaintRepository.submitComplaint(
        clientName: clientName,
        description: desc,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back();
        Get.snackbar('success'.tr, 'complaint_sent'.tr);
        complaintClientController.clear();
        complaintDescController.clear();
      } else {
        Get.snackbar('error'.tr, 'server_error'.tr);
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'complaint_send_error'.tr);
    } finally {
      isSubmittingComplaint.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    complaintClientController.dispose();
    complaintDescController.dispose();
    super.onClose();
  }
}