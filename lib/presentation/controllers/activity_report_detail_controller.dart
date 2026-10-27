import 'package:get/get.dart';
import '../../core/services/session_service.dart';
import '../../domain/entities/activity_report.dart';
import '../../domain/usecases/activity_report_usecases.dart';
import '../../utils/activity_report_feedback.dart';

class ActivityReportDetailController extends GetxController {
  ActivityReportDetailController({
    ActivityReportUseCases? reports,
    String? name,
    String Function()? tokenProvider,
  }) : _reports = reports ?? Get.find<ActivityReportUseCases>(),
       _name = name ?? '',
       _tokenProvider = tokenProvider;
  final ActivityReportUseCases _reports;
  final String Function()? _tokenProvider;
  String _name;
  final report = Rxn<ActivityReport>();
  final canWrite = false.obs;
  final loading = true.obs;
  final error = ''.obs;
  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is Map) {
      _name = Get.arguments['name']?.toString() ?? _name;
    }
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = '';
    canWrite.value = false;
    try {
      final result = await _reports.detail(
        token: _tokenProvider?.call() ?? Get.find<SessionService>().authToken,
        name: _name,
      );
      if (isClosed) return;
      report.value = result.report;
      canWrite.value = result.canRead && result.canWrite;
    } catch (e) {
      if (!isClosed) {
        report.value = null;
        error.value = activityReportError(e);
      }
    } finally {
      if (!isClosed) loading.value = false;
    }
  }
}
