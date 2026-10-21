import 'package:get/get.dart';

import '../../core/services/session_service.dart';
import '../../domain/entities/job_profile.dart';
import '../../domain/failures/failures.dart';
import '../../domain/usecases/usecases.dart';
import '../../utils/error_feedback.dart';

class JobProfileController extends GetxController {
  JobProfileController({JobProfileUseCases? jobProfiles})
      : _jobProfiles = jobProfiles ?? Get.find<JobProfileUseCases>();

  final JobProfileUseCases _jobProfiles;

  final isLoading = true.obs;
  final employee = Rxn<EmployeeHeader>();
  final profile = Rxn<JobProfile>();
  final emptyMessage = ''.obs;
  final errorMessage = ''.obs;

  String get _token => Get.find<SessionService>().authToken;

  bool get hasProfile => profile.value != null;
  bool get hasError => errorMessage.value.isNotEmpty;

  String get headerName {
    final e = employee.value;
    if (e == null) return '';
    return e.employeeName.isNotEmpty ? e.employeeName : e.name;
  }

  String get headerTitle {
    final p = profile.value;
    final e = employee.value;
    final jobTitle = p?.jobTitle.trim() ?? '';
    if (jobTitle.isNotEmpty) return jobTitle;
    return e?.designation.trim() ?? '';
  }

  String get headerCompany => employee.value?.company ?? '';

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    isLoading.value = true;
    errorMessage.value = '';
    emptyMessage.value = '';
    try {
      final res = await _jobProfiles.fetchMyJobProfile(token: _token);
      if (res.error != null && res.error!.trim().isNotEmpty) {
        employee.value = res.employee;
        profile.value = null;
        errorMessage.value = res.error!;
        return;
      }
      employee.value = res.employee;
      profile.value = res.jobProfile;
      if (res.jobProfile == null) {
        emptyMessage.value = (res.message != null && res.message!.trim().isNotEmpty)
            ? res.message!.trim()
            : 'job_profile_empty'.tr;
      }
    } catch (e) {
      if (e is InvalidSessionException || e is AccessDeniedException) {
        return;
      }
      errorMessage.value = ErrorFeedback.message(
        e,
        fallbackKey: 'failed_load_job_profile',
      );
      ErrorFeedback.snackbar(e, fallbackKey: 'failed_load_job_profile');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onRefresh() => fetchProfile();
}
