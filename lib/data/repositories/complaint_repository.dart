// ignore_for_file: annotate_overrides
import '../../core/network/api_client.dart';
import '../../domain/failures/failures.dart';
import '../../domain/repositories/complaint_repository.dart';

class ComplaintRepositoryImpl implements ComplaintRepository {
  ComplaintRepositoryImpl(this._client);

  final ApiClient _client;

  Future<void> submitComplaint({required String description}) async {
    final json = await _client.postCustomerMethod(
      'create_customer_complaint',
      body: {'description': description},
    );
    final result = _client.unwrap(json);
    if (result is! Map || result['message'] != 'Success' || result['id'] is! String) {
      throw const RepositoryException('Missing complaint confirmation');
    }
  }
}
