import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/session_service.dart';
import '../../domain/entities/activity_report.dart';
import '../../domain/usecases/activity_report_usecases.dart';
import '../../utils/activity_report_feedback.dart';

class ActivityReportListController extends GetxController {
  ActivityReportListController({
    ActivityReportUseCases? reports,
    String Function()? tokenProvider,
  }) : _reports = reports ?? Get.find<ActivityReportUseCases>(),
       _tokenProvider = tokenProvider;
  final ActivityReportUseCases _reports;
  final String Function()? _tokenProvider;
  final items = <ActivityReport>[].obs;
  final total = 0.obs;
  final canCreate = false.obs;
  final loading = true.obs;
  final loadingMore = false.obs;
  final hasMore = false.obs;
  final error = ''.obs;
  final search = ''.obs;
  final type = ''.obs;
  final fromDate = ''.obs;
  final toDate = ''.obs;
  final searchController = TextEditingController();
  Worker? _worker;
  int _generation = 0;
  int _offset = 0;
  String get token =>
      _tokenProvider?.call() ?? Get.find<SessionService>().authToken;
  bool get hasFilters =>
      type.value.isNotEmpty ||
      fromDate.value.isNotEmpty ||
      toDate.value.isNotEmpty;
  @override
  void onInit() {
    super.onInit();
    _worker = debounce(
      search,
      (_) => refreshReports(),
      time: const Duration(milliseconds: 350),
    );
    refreshReports();
  }

  @override
  void onClose() {
    _generation++;
    _worker?.dispose();
    searchController.dispose();
    super.onClose();
  }

  Future<void> refreshReports() async {
    final generation = ++_generation;
    _offset = 0;
    items.clear();
    total.value = 0;
    error.value = '';
    loading.value = true;
    loadingMore.value = false;
    hasMore.value = false;
    await _fetch(generation);
  }

  Future<void> loadMore() async {
    if (loading.value || loadingMore.value || !hasMore.value) return;
    loadingMore.value = true;
    error.value = '';
    await _fetch(_generation, more: true);
  }

  Future<void> _fetch(int generation, {bool more = false}) async {
    try {
      final result = await _reports.list(
        token: token,
        search: search.value.trim(),
        type: type.value,
        fromDate: fromDate.value,
        toDate: toDate.value,
        offset: _offset,
      );
      if (generation != _generation || isClosed) return;
      canCreate.value = result.canCreate;
      total.value = result.total;
      hasMore.value = result.hasMore;
      if (more) {
        final known = items.map((r) => r.name).toSet();
        items.addAll(result.reports.where((r) => !known.contains(r.name)));
      } else {
        items.assignAll(result.reports);
      }
      _offset += result.reports.length;
    } catch (e) {
      if (generation != _generation || isClosed) return;
      error.value = activityReportError(e);
      if (!more) canCreate.value = false;
    } finally {
      if (generation == _generation && !isClosed) {
        loading.value = false;
        loadingMore.value = false;
      }
    }
  }

  void applyFilters(String value, String from, String to) {
    type.value = value;
    fromDate.value = from;
    toDate.value = to;
    refreshReports();
  }
}
