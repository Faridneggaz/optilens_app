import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';

class JopticComplaintRepository {
  JopticComplaintRepository(this._client);

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
