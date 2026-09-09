import '../entities/announcement.dart';

abstract class AnnouncementRepository {
  Future<List<Announcement>> fetchAnnouncements(
    String customerCode, {
    int limit = 10,
    int offset = 0,
  });
}
