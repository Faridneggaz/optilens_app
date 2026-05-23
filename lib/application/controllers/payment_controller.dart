import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/payment_repository.dart';
import '../../utils/payment_utils.dart';
import 'session_controller.dart';

class PaymentController extends GetxController {
  final _repo = PaymentRepository();

  final payments      = <PaymentItemData>[].obs;
  final isLoading     = true.obs;
  final isLoadingMore = false.obs;
  final hasMore       = true.obs;
  final expandedIndex = Rxn<int>();
  
  final searchQuery    = ''.obs;
  final isSearching    = false.obs;
  final selectedStatus = 'All'.obs;
  final searchPayments = <PaymentItemData>[].obs;
  final searchController = TextEditingController();
  Worker? _debounce;
  
  List<PaymentItemData> get displayPayments => searchQuery.value.isNotEmpty ? searchPayments : payments;

  int _offset = 0;
  static const int _limit = PaymentRepository.pageSize;

  void toggleExpand(int index) {
    expandedIndex.value = expandedIndex.value == index ? null : index;
  }

  @override
  void onInit() {
    super.onInit();
    final code = Get.find<SessionController>().customer.value?.code ?? '';
    
    _debounce = debounce(searchQuery, (query) {
      if (query.isNotEmpty) {
        fetchSearchResults(code);
      } else {
        isSearching.value = false;
        searchPayments.clear();
      }
    }, time: const Duration(milliseconds: 400));

    ever(selectedStatus, (_) {
      if (searchQuery.value.isNotEmpty) {
        fetchSearchResults(code);
      } else {
        onRefresh();
      }
    });

    loadPayments(code);
  }

  @override
  void onClose() {
    _debounce?.dispose();
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadPayments(String customerCode) async {
    isLoading.value = true;
    _offset = 0;
    payments.clear();
    hasMore.value = true;
    try {
      final response = await _repo.fetchPayments(
        customerCode,
        limit: _limit,
        offset: _offset,
        status: selectedStatus.value == 'All' ? null : selectedStatus.value,
      );
      payments.value = _mapPayments(response.payments);
      hasMore.value  = response.hasMore;
      _offset        = payments.length;
    } catch (e) {
      // Ignored for production
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onLoadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      final code = Get.find<SessionController>().customer.value?.code ?? '';
      final response = await _repo.fetchPayments(
        code,
        limit: _limit,
        offset: _offset,
        status: selectedStatus.value == 'All' ? null : selectedStatus.value,
      );
      payments.addAll(_mapPayments(response.payments));
      hasMore.value = response.hasMore;
      _offset       = payments.length;
    } catch (e) {
      // Ignored for production
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> onRefresh() async {
    final code = Get.find<SessionController>().customer.value?.code ?? '';
    await loadPayments(code);
  }

  Future<void> fetchSearchResults(String customerCode) async {
    isSearching.value = true;
    try {
      final response = await _repo.fetchPayments(
        customerCode,
        limit: 20,
        offset: 0,
        searchText: searchQuery.value,
        status: selectedStatus.value == 'All' ? null : selectedStatus.value,
      );
      searchPayments.value = _mapPayments(response.payments);
    } catch (_) {
      // Ignored for production
    } finally {
      isSearching.value = false;
    }
  }

  List<PaymentItemData> _mapPayments(List<dynamic> payments) {
    return payments.map((p) {
      return PaymentItemData(
        paymentId: p.name as String,
        date: p.postingDate as String,
        invoices: (p.invoicesPayed as List<dynamic>)
            .map((inv) => PaidInvoice(
                  invoiceId: inv.invoice as String,
                  amount: inv.allocatedAmount as double,
                ))
            .toList(),
      );
    }).toList();
  }
}