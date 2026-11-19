import '../entities/announcement.dart';

abstract class AnnouncementRepository {
  Future<List<Announcement>> fetchAnnouncements({
    int limit = 10,
    int offset = 0,
  });
}
