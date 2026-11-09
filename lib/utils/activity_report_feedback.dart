import 'package:get/get.dart';
import '../domain/failures/failures.dart';
import 'error_feedback.dart';

String activityReportError(Object error) {
  if (error is AccessDeniedException) return 'error_access_denied'.tr;
  final text = error is RepositoryException ? error.message : '';
  final key = switch (text) {
    'Report has changed. Refresh before saving.' => 'ar_conflict',
    'Report title is required' ||
    'Report title and type are required' => 'ar_title_required',
    'Action description is required' => 'ar_description_required',
    'Duplicate participant' => 'ar_duplicate_participant',
    'Responsible employee needs an ERP user account' =>
      'ar_employee_user_missing',
    'Invalid date range' => 'ar_dates_invalid',
    'Activity Report not found' => 'ar_not_found',
    _ => '',
  };
  return key.isNotEmpty
      ? key.tr
      : ErrorFeedback.message(
          error,
          fallbackKey: 'ar_load_failed',
        ).replaceAll(RegExp(r'<[^>]+>'), '');
}
