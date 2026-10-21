import '../repositories/joptic_complaint_repository.dart';
import '../repositories/lead_repository.dart';

class JopticUseCases {
  JopticUseCases(this._leads, this._complaints);
  final LeadRepository _leads;
  final JopticComplaintRepository _complaints;

  Future<void> createLead({required String name, required String phone}) =>
      _leads.createLead(name: name, phone: phone);

  Future<void> submitComplaint({
    required String clientName,
    required String description,
  }) =>
      _complaints.submitComplaint(
        clientName: clientName,
        description: description,
      );
}
