// ignore_for_file: annotate_overrides
import '../../core/network/api_client.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../mappers/json_mappers.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl(this._client);

  final ApiClient _client;

  Future<List<Announcement>> fetchAnnouncements({
    int limit = 10,
    int offset = 0,
  }) async {
    final json = await _client.getCustomerMethod(
      'get_customer_announcements',
      query: {'limit': '$limit', 'offset': '$offset'},
    );
    final message = _client.unwrap(json);
    if (message is Map && message.containsKey('announcements')) {
      final list = message['announcements'] as List<dynamic>;
      return list
          .map((item) => AnnouncementMapper.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
    }
    return [];
  }
}
