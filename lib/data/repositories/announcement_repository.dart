import '../../core/network/api_client.dart';
import '../../domain/response/announcement.dart';

class AnnouncementRepository {
  AnnouncementRepository(this._client);

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
      return list.map((item) => Announcement.fromJson(item)).toList();
    }
    return [];
  }
}
