import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../core/services/session_service.dart';
import '../../domain/entities/manque.dart';
import '../../domain/failures/failures.dart';
import '../../domain/results/action_result.dart';
import '../../domain/usecases/usecases.dart';
import '../../utils/error_feedback.dart';
import '../../utils/manque_status_helper.dart';

class CommandeManqueController extends GetxController {
  CommandeManqueController({
    ManqueUseCases? manque,
    MaterialRequestUseCases? materialRequests,
  })  : _manque = manque ?? Get.find<ManqueUseCases>(),
        _mr = materialRequests ?? Get.find<MaterialRequestUseCases>();

  final ManqueUseCases _manque;
  final MaterialRequestUseCases _mr;

  final items = <CommandeDeManque>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final searchQuery = ''.obs;
  final selectedStatus = 'All'.obs;
  final canCreate = true.obs;

  final buyers = <BuyerOption>[].obs;
  final customers = <CustomerOption>[].obs;
  final customersLoading = false.obs;
  final companies = <String>[].obs;
  final warehouses = <Map<String, String>>[].obs;

  final searchController = TextEditingController();
  Worker? _debounce;
  int _offset = 0;
  static const int _limit = 50;

  String get _token => Get.find<SessionService>().authToken;

  List<CommandeDeManque> get displayList => items;

  @override
  void onInit() {
    super.onInit();
    _debounce = debounce(
      searchQuery,
      (_) => onRefresh(),
      time: const Duration(milliseconds: 400),
    );
    ever(selectedStatus, (_) => onRefresh());
    onRefresh();
    loadLookups();
  }

  @override
  void onClose() {
    _debounce?.dispose();
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadLookups() async {
    await Future.wait([loadCompanies(), loadBuyers()]);
    final company = companies.isNotEmpty ? companies.first : 'OPTILENS ALGER';
    await loadWarehouses(company);
  }

  Future<void> loadBuyers() async {
    try {
      buyers.value = await _manque.fetchBuyers(token: _token);
    } catch (e) {
      if (e is! InvalidSessionException && e is! AccessDeniedException) {
        ErrorFeedback.snackbar(e, fallbackKey: 'manque_failed_load_buyers');
      }
    }
  }

  Future<void> loadCompanies() async {
    try {
      final res = await _mr.fetchCompanies(token: _token);
      if (res.isNotEmpty) {
        companies.value = res;
        return;
      }
    } catch (_) {}
    final allowed = Get.find<SessionService>().getAllowedCompanies();
    if (allowed.isNotEmpty) companies.value = allowed;
  }

  Future<void> loadCustomers(String company, {String? search}) async {
    if (company.trim().isEmpty) {
      customers.clear();
      return;
    }
    customersLoading.value = true;
    try {
      customers.value = await _manque.fetchCustomers(
        token: _token,
        company: company,
        searchText: search,
      );
    } catch (e) {
      if (e is! InvalidSessionException && e is! AccessDeniedException) {
        ErrorFeedback.snackbar(e, fallbackKey: 'manque_failed_load_customers');
      }
    } finally {
      customersLoading.value = false;
    }
  }

  Future<void> loadWarehouses(String company) async {
    try {
      warehouses.value =
          await _mr.fetchWarehouses(token: _token, company: company);
    } catch (e) {
      if (e is! InvalidSessionException && e is! AccessDeniedException) {
        ErrorFeedback.snackbar(e, fallbackKey: 'manque_failed_load');
      }
    }
  }

  Future<List<Map<String, String>>> searchItems(String q) async {
    try {
      return await _mr.searchItems(token: _token, searchText: q);
    } catch (_) {
      return const [];
    }
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
      final response = await _manque.fetchCommandes(
        token: _token,
        limit: _limit,
        offset: _offset,
        searchText:
            searchQuery.value.trim().isEmpty ? null : searchQuery.value.trim(),
        status: selectedStatus.value,
      );
      if (isLoadMore) {
        final existing = items.map((e) => e.name).toSet();
        items.addAll(response.commandes.where((e) => !existing.contains(e.name)));
      } else {
        items.value = response.commandes;
      }
      hasMore.value = response.hasMore;
      if (response.commandes.isNotEmpty) {
        _offset += response.commandes.length;
      }
    } catch (e) {
      if (e is InvalidSessionException || e is AccessDeniedException) return;
      ErrorFeedback.snackbar(e, fallbackKey: 'manque_failed_load');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<ActionResult> createCommande({
    required String company,
    required String warehouse,
    required String buyer,
    required String customer,
    String customerName = '',
    String? transactionDate,
    required List<Map<String, dynamic>> lineItems,
    required bool envoyer,
  }) async {
    final result = await _manque.createCommande(
      token: _token,
      company: company,
      warehouse: warehouse,
      buyer: buyer,
      customer: customer,
      customerName: customerName,
      transactionDate: transactionDate,
      items: lineItems,
      envoyer: envoyer,
    );
    if (result.isAuthHandled ||
        (result.error?.toLowerCase().contains('access denied') ?? false)) {
      canCreate.value = false;
      return result;
    }
    if (result.isSuccess) {
      await onRefresh();
    }
    return result;
  }

  Future<ActionResult> manageCommande(String name, String action) async {
    final result = await _manque.manageCommande(
      token: _token,
      name: name,
      action: action,
    );
    if (result.isSuccess) await onRefresh();
    return result;
  }

  void openDetail(CommandeDeManque cmd) {
    Get.toNamed(AppRoutes.commandeManqueDetail, arguments: {'name': cmd.name});
  }

  void openForm() {
    Get.toNamed(AppRoutes.commandeManqueForm);
  }

  String statusLabel(String value) {
    if (value == 'All') return 'manque_filter_all'.tr;
    return value;
  }

  List<String> get statusFilters => commandeManqueStatuses;
}
