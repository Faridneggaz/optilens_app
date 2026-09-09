import '../../core/network/api_client.dart';

class ComplaintRepository {
  ComplaintRepository(this._client);

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
