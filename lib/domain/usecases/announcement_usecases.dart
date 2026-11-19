import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

class AnnouncementUseCases {
  AnnouncementUseCases(this._repo);
  final AnnouncementRepository _repo;

  Future<List<Announcement>> fetchAnnouncements({
    int limit = 10,
    int offset = 0,
  }) =>
      _repo.fetchAnnouncements(limit: limit, offset: offset);
}
