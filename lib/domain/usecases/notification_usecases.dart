import '../repositories/notification_repository.dart';

class NotificationUseCases {
  NotificationUseCases(this._repo);
  final NotificationRepository _repo;

  Future<List<dynamic>> fetchNotifications(String customerCode) =>
      _repo.fetchNotifications(customerCode);
}
