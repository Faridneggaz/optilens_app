import 'package:intl/intl.dart';

// ignore_for_file: annotate_overrides
import '../../core/network/api_client.dart';
import '../../domain/repositories/joptic_complaint_repository.dart';

class JopticComplaintRepositoryImpl implements JopticComplaintRepository {
  JopticComplaintRepositoryImpl(this._client);

  final ApiClient _client;

  Future<void> submitComplaint({
    required String clientName,
    required String description,
  }) {
    return _client.postErpResource('reclamtion client', {
      'client': clientName,
      'desciption_reclamation': description,
      'date_reception': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    });
  }
}
