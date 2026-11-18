import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/usecases/usecases.dart';
import '../../widgets/payment/payment_list.dart';
import '../../utils/error_feedback.dart';

class PaymentController extends GetxController {
  PaymentController({PaymentUseCases? payments})
      : _payments = payments ?? Get.find<PaymentUseCases>();

  final PaymentUseCases _payments;

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
  static const int _limit = 20;

  void toggleExpand(int index) {
    expandedIndex.value = expandedIndex.value == index ? null : index;
  }

  @override
  void onInit() {
    super.onInit();
    
    _debounce = debounce(searchQuery, (query) {
      if (query.isNotEmpty) {
        fetchSearchResults();
      } else {
        isSearching.value = false;
        searchPayments.clear();
      }
    }, time: const Duration(milliseconds: 400));

    ever(selectedStatus, (_) {
      if (searchQuery.value.isNotEmpty) {
        fetchSearchResults();
      } else {
        onRefresh();
      }
    });

    loadPayments();
  }

  @override
  void onClose() {
    _debounce?.dispose();
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadPayments() async {
    isLoading.value = true;
    _offset = 0;
    payments.clear();
    hasMore.value = true;
    try {
      final response = await _payments.fetchPayments(
        limit: _limit,
        offset: _offset,
        status: selectedStatus.value == 'All' ? null : selectedStatus.value,
      );
      payments.value = _mapPayments(response.payments);
      hasMore.value  = response.hasMore;
      _offset        = payments.length;
    } catch (e) {
      ErrorFeedback.snackbar(e, fallbackKey: 'error_load_payments');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onLoadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      final response = await _payments.fetchPayments(
        limit: _limit,
        offset: _offset,
        status: selectedStatus.value == 'All' ? null : selectedStatus.value,
      );
      payments.addAll(_mapPayments(response.payments));
      hasMore.value = response.hasMore;
      _offset       = payments.length;
    } catch (e) {
      ErrorFeedback.snackbar(e, fallbackKey: 'error_load_payments');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> onRefresh() => loadPayments();

  Future<void> fetchSearchResults() async {
    isSearching.value = true;
    try {
      final response = await _payments.fetchPayments(
        limit: 20,
        offset: 0,
        searchText: searchQuery.value,
        status: selectedStatus.value == 'All' ? null : selectedStatus.value,
      );
      searchPayments.value = _mapPayments(response.payments);
    } catch (e) {
      ErrorFeedback.snackbar(e, fallbackKey: 'error_search_payments');
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
