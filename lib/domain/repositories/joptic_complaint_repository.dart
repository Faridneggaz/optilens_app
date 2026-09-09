abstract class JopticComplaintRepository {
  Future<void> submitComplaint({
    required String clientName,
    required String description,
  });
}
