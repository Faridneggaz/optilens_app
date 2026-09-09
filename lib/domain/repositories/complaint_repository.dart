abstract class ComplaintRepository {
  Future<void> submitComplaint({
    required String client,
    required String description,
  });
}
