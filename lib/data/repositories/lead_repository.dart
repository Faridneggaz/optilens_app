// ignore_for_file: annotate_overrides
import '../../core/network/api_client.dart';
import '../../domain/repositories/lead_repository.dart';

class LeadRepositoryImpl implements LeadRepository {
  LeadRepositoryImpl(this._client);

  final ApiClient _client;

  Future<void> createLead({required String name, required String phone}) {
    return _client.postErpResource('Lead', {
      'lead_name': name,
      'company_name': name,
      'mobile_no': phone,
      'status': 'Lead',
      'description':
          'Demande d\'abonnement via l\'application mobile J-Optic',
    });
  }
}
