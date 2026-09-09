// ignore_for_file: annotate_overrides
import '../../core/network/api_client.dart';
import '../../domain/repositories/complaint_repository.dart';

class ComplaintRepositoryImpl implements ComplaintRepository {
  ComplaintRepositoryImpl(this._client);

  final ApiClient _client;

  Future<void> submitComplaint({
    required String client,
    required String description,
  }) {
    return _client.postMobile(
      'create_customer_complaint',
      body: {'client': client, 'description': description},
      attachToken: false,
    );
  }
}
