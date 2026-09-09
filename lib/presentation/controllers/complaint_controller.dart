import 'package:get/get.dart';
import '../../domain/usecases/usecases.dart';
import '../../utils/error_feedback.dart';

class ComplaintController extends GetxController {
  ComplaintController({ComplaintUseCases? complaints})
      : _complaints = complaints ?? Get.find<ComplaintUseCases>();

  final ComplaintUseCases _complaints;
  final isLoading = false.obs;

  Future<bool> submitComplaint({
    required String client,
    required String description,
  }) async {
    isLoading.value = true;
    try {
      await _complaints.submitComplaint(client: client, description: description);
      return true;
    } catch (e) {
      ErrorFeedback.snackbar(e, fallbackKey: 'complaint_send_error');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}