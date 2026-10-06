import '../repositories/complaint_repository.dart';

class ComplaintUseCases {
  ComplaintUseCases(this._repo);
  final ComplaintRepository _repo;

  Future<void> submitComplaint({
    required String client,
    required String description,
  }) =>
      _repo.submitComplaint(client: client, description: description);
}
