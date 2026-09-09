import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/network/api_client.dart';
import '../../data/repositories/lead_repository.dart';
import '../../data/repositories/complaint_joptic_repository.dart';

class AboutController extends GetxController {
  AboutController({
    LeadRepository? leadRepository,
    JopticComplaintRepository? complaintRepository,
  })  : _leadRepository =
            leadRepository ?? LeadRepository(Get.find<ApiClient>()),
        _complaintRepository = complaintRepository ??
            JopticComplaintRepository(Get.find<ApiClient>());

  final LeadRepository _leadRepository;
  final JopticComplaintRepository _complaintRepository;

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
      await _leadRepository.createLead(name: name, phone: phone);
      Get.back();
      Get.snackbar('success'.tr, 'request_received'.tr);
      nameController.clear();
      phoneController.clear();
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
      await _complaintRepository.submitComplaint(
        clientName: clientName,
        description: desc,
      );
      Get.back();
      Get.snackbar('success'.tr, 'complaint_sent'.tr);
      complaintClientController.clear();
      complaintDescController.clear();
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
