import 'package:get/get.dart';
import '../../core/services/session_service.dart';
import '../../domain/usecases/usecases.dart';
import '../../utils/error_feedback.dart';

class NotificationController extends GetxController {
  NotificationController({NotificationUseCases? notifications})
      : _notifications = notifications ?? Get.find<NotificationUseCases>();

  final NotificationUseCases _notifications;

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
      final result = await _notifications.fetchNotifications(code);
      notifications.value = result;
    } catch (e) {
      notifications.value = [];
      ErrorFeedback.snackbar(e, fallbackKey: 'error_load_notifications');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onRefresh() async {
    await fetchNotifications();
  }
}
