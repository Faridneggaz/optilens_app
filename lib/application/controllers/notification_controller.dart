import 'package:get/get.dart';
import '../../core/services/session_service.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationController extends GetxController {
  final _repo = NotificationRepository();

  final notifications = <dynamic>[].obs;
  final isLoading     = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    try {
      // Get customer code from session
      final code = Get.find<SessionService>().userCode;
      if (code.isEmpty) {
        notifications.value = [];
        return;
      }
      final result = await _repo.fetchNotifications(code);
      notifications.value = result;
    } catch (_) {
      notifications.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onRefresh() async {
    await fetchNotifications();
  }
}
