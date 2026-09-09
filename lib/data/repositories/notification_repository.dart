// ignore_for_file: annotate_overrides
import '../../core/network/api_client.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._client);

  final ApiClient _client;

  Future<List<dynamic>> fetchNotifications(String customerCode) async {
    final json = await _client.getMobile(
      'get_notification_by_customer_code',
      query: {'code': customerCode},
      attachToken: false,
    );
    final message = json['message'];
    if (message == null) return [];
    final list = message['notification'];
    if (list == null) return [];
    return List<dynamic>.from(list as List);
  }
}
