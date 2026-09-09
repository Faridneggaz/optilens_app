// ignore_for_file: annotate_overrides
import '../../core/network/api_client.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../mappers/json_mappers.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl(this._client);

  final ApiClient _client;

  Future<List<Announcement>> fetchAnnouncements(
    String customerCode, {
    int limit = 10,
    int offset = 0,
  }) async {
    final json = await _client.getMobile(
      'get_announcements_by_customer_code',
      query: {
        'code': customerCode,
        'limit': '$limit',
        'offset': '$offset',
      },
      attachToken: false,
    );
    final message = json['message'];
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
