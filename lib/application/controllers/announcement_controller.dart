import 'package:get/get.dart';
import '../../data/repositories/announcement_repository.dart';
import '../../domain/response/announcement.dart';

class AnnouncementController extends GetxController {
  final AnnouncementRepository _repo = AnnouncementRepository();

  Future<List<Announcement>> fetchAnnouncements(
    String customerCode, {
    int limit  = 10,
    int offset = 0,
  }) async {
    try {
      return await _repo.fetchAnnouncements(customerCode,
          limit: limit, offset: offset);
    } catch (_) {
      return [];
    }
  }
}