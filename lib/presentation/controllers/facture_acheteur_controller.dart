import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../core/services/session_service.dart';
import '../../domain/entities/manque.dart';
import '../../domain/failures/failures.dart';
import '../../domain/usecases/usecases.dart';
import '../../utils/error_feedback.dart';
import '../../utils/manque_status_helper.dart';

class FactureAcheteurController extends GetxController {
  FactureAcheteurController({ManqueUseCases? manque})
      : _manque = manque ?? Get.find<ManqueUseCases>();

  final ManqueUseCases _manque;

  final items = <FactureAcheteur>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final searchQuery = ''.obs;
  final selectedStatus = 'All'.obs;
  /// When true, list focuses Validée + Poche for reimbursement.
  final rembourserOnly = false.obs;

  final searchController = TextEditingController();
  Worker? _debounce;
  int _offset = 0;
  static const int _limit = 50;

  String get _token => Get.find<SessionService>().authToken;

  List<FactureAcheteur> get displayList {
    if (!rembourserOnly.value) return items;
    return items
        .where((f) => f.isPoche && f.isValidee && !f.isRembourse)
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['rembourser'] == true) {
      rembourserOnly.value = true;
      selectedStatus.value = 'Validée';
    }
    _debounce = debounce(
      searchQuery,
      (_) => onRefresh(),
      time: const Duration(milliseconds: 400),
    );
    ever(selectedStatus, (_) => onRefresh());
    onRefresh();
  }

  @override
  void onClose() {
    _debounce?.dispose();
    searchController.dispose();
    super.onClose();
  }

  Future<void> onRefresh() async {
    isLoading.value = true;
    hasMore.value = true;
    _offset = 0;
    items.clear();
    await fetchList();
  }

  Future<void> onLoadMore() async {
    if (!isLoadingMore.value && hasMore.value) {
      await fetchList(isLoadMore: true);
    }
  }

  Future<void> fetchList({bool isLoadMore = false}) async {
    try {
      if (isLoadMore) {
        isLoadingMore.value = true;
      } else if (items.isEmpty) {
        isLoading.value = true;
      }
      final response = await _manque.fetchFactures(
        token: _token,
        limit: _limit,
        offset: _offset,
        searchText:
            searchQuery.value.trim().isEmpty ? null : searchQuery.value.trim(),
        status: selectedStatus.value,
      );
      if (isLoadMore) {
        final existing = items.map((e) => e.name).toSet();
        items.addAll(response.factures.where((e) => !existing.contains(e.name)));
      } else {
        items.value = response.factures;
      }
      hasMore.value = response.hasMore;
      if (response.factures.isNotEmpty) {
        _offset += response.factures.length;
      }
    } catch (e) {
      if (e is InvalidSessionException || e is AccessDeniedException) return;
      ErrorFeedback.snackbar(e, fallbackKey: 'manque_failed_load_factures');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  void openForm(FactureAcheteur f) {
    Get.toNamed(AppRoutes.factureAcheteurForm, arguments: {'name': f.name});
  }

  List<String> get statusFilters => factureAcheteurStatuses;

  String statusLabel(String value) {
    if (value == 'All') return 'manque_filter_all'.tr;
    return value;
  }
}
