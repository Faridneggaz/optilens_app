// ignore_for_file: annotate_overrides
import '../../core/network/api_client.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._client);

  final ApiClient _client;

  Future<List<dynamic>> fetchNotifications() async {
    final json = await _client.getCustomerMethod('get_customer_notifications');
    final message = _client.unwrap(json);
    return message is Map && message['notification'] is List
        ? List<dynamic>.from(message['notification'] as List)
        : [];
  }
}
