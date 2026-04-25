import 'package:get/get.dart';
import '../../data/repositories/complaint_repository.dart';

class ComplaintController extends GetxController {
  final _repo     = ComplaintRepository();
  final isLoading = false.obs;

  Future<bool> submitComplaint({
    required String client,
    required String description,
  }) async {
    isLoading.value = true;
    try {
      await _repo.submitComplaint(client: client, description: description);
      return true;
    } catch (_) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}