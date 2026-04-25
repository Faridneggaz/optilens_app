import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';
import '../../domain/response/announcement.dart';
import 'repository_exception.dart';

class AnnouncementRepository {
  final String _baseUrl =
      '${ApiConfig.mobileAppApiPath}get_announcements_by_customer_code';

  Future<List<Announcement>> fetchAnnouncements(
    String customerCode, {
    int limit = 10,
    int offset = 0,
  }) async {
    final url = Uri.parse('$_baseUrl?code=$customerCode&limit=$limit&offset=$offset');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = json.decode(response.body);
        if (responseJson.containsKey('message')) {
          final dynamic messageContent = responseJson['message'];
          if (messageContent is Map &&
              messageContent.containsKey('announcements')) {
            final List<dynamic> list = messageContent['announcements'];
            return list.map((item) => Announcement.fromJson(item)).toList();
          }
        }
        return [];
      }
      throw RepositoryException('Server error: ${response.statusCode}');
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }
}
