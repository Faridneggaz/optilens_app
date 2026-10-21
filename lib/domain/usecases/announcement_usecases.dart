import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

class AnnouncementUseCases {
  AnnouncementUseCases(this._repo);
  final AnnouncementRepository _repo;

  Future<List<Announcement>> fetchAnnouncements(
    String customerCode, {
    int limit = 10,
    int offset = 0,
  }) =>
      _repo.fetchAnnouncements(customerCode, limit: limit, offset: offset);
}
