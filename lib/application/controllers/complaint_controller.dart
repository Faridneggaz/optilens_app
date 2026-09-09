import 'package:get/get.dart';
import '../../data/repositories/complaint_repository.dart';
import '../../utils/error_feedback.dart';

class ComplaintController extends GetxController {
  ComplaintController({ComplaintRepository? repo})
      : _repo = repo ?? Get.find<ComplaintRepository>();

  final ComplaintRepository _repo;
  final isLoading = false.obs;

  Future<bool> submitComplaint({
    required String client,
    required String description,
  }) async {
    isLoading.value = true;
    try {
      await _repo.submitComplaint(client: client, description: description);
      return true;
    } catch (e) {
      ErrorFeedback.snackbar(e, fallbackKey: 'complaint_send_error');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}