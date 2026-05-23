import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../domain/response/sales_invoice.dart';
import '../../utils/invoice_utils.dart';
import 'session_controller.dart';

class InvoiceController extends GetxController {
  final _repo = InvoiceRepository();

  final salesInvoices     = <SalesInvoice>[].obs;
  final posInvoices       = <SalesInvoice>[].obs;
  final isLoading         = true.obs;
  final isLoadingMore     = false.obs;
  final hasMore           = true.obs;
  final selectedTab       = 0.obs;
  final searchQuery       = ''.obs;
  final selectedStatus    = 'All'.obs;
  final isHeaderVisible   = true.obs;
  final isSearching       = false.obs;
  final searchSalesInvoices = <SalesInvoice>[].obs;
  final searchPosInvoices   = <SalesInvoice>[].obs;
  Worker? _debounce;

  int _offset = 0;
  static const int _limit = 20;
  double _lastScrollOffset = 0;
  late final ScrollController scrollController;
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    scrollController = ScrollController()..addListener(_onScroll);
    
    _debounce = debounce(searchQuery, (query) {
      if (query.isNotEmpty) {
        fetchSearchResults();
      } else {
        isSearching.value = false;
        searchSalesInvoices.clear();
        searchPosInvoices.clear();
      }
    }, time: const Duration(milliseconds: 400));

    ever(selectedStatus, (_) {
      if (searchQuery.value.isNotEmpty) {
        fetchSearchResults();
      } else {
        onRefresh();
      }
    });

    fetchInvoices();
  }

  @override
  void onClose() {
    _debounce?.dispose();
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _onScroll() {
    final current = scrollController.offset;
    if (current > _lastScrollOffset && current > 50) {
      isHeaderVisible.value = false;
    } else if (current < _lastScrollOffset) {
      isHeaderVisible.value = true;
    }
    _lastScrollOffset = current;
  }

  String get _customerCode =>
      Get.find<SessionController>().customer.value?.code ?? '';

  List<InvoiceItemData> get filteredSalesItems {
    final list = searchQuery.value.isNotEmpty ? searchSalesInvoices : salesInvoices;
    return list.map((i) => InvoiceItemData(
      title: i.name,
      ttc: i.outstandingAmount,
      price: i.grandTotal,
      postingDate: i.postingDate,
      status: i.status,
    )).toList();
  }

  List<InvoiceItemData> get filteredPOSItems {
    final list = searchQuery.value.isNotEmpty ? searchPosInvoices : posInvoices;
    return list.map((i) => InvoiceItemData(
      title: i.name,
      ttc: i.outstandingAmount,
      price: i.grandTotal,
      postingDate: i.postingDate,
      status: i.status,
    )).toList();
  }

  Future<void> onRefresh() async {
    isLoading.value = true;
    hasMore.value   = true;
    _offset         = 0;
    salesInvoices.clear();
    posInvoices.clear();
    await fetchInvoices();
  }

  Future<void> onLoadMore() async {
    if (!isLoadingMore.value && hasMore.value) {
      await fetchInvoices(isLoadMore: true);
    }
  }

  Future<void> fetchInvoices({bool isLoadMore = false}) async {
    try {
      if (isLoadMore) {
        isLoadingMore.value = true;
      } else if (salesInvoices.isEmpty && posInvoices.isEmpty) {
        isLoading.value = true;
      }

      final response = await _repo.fetchInvoices(
        _customerCode,
        limit: _limit,
        offset: _offset,
        status: selectedStatus.value == 'All' ? null : selectedStatus.value,
      );

      if (isLoadMore) {
        salesInvoices.addAll(response.salesInvoices);
        posInvoices.addAll(response.posInvoices);
      } else {
        salesInvoices.value = response.salesInvoices;
        posInvoices.value   = response.posInvoices;
      }

      if (response.salesInvoices.length < _limit &&
          response.posInvoices.length < _limit) {
        hasMore.value = false;
      } else {
        _offset += _limit;
      }
    } catch (_) {
      Get.snackbar('Erreur', 'Impossible de charger les factures');
    } finally {
      isLoading.value     = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> fetchSearchResults() async {
    isSearching.value = true;
    try {
      final response = await _repo.fetchInvoices(
        _customerCode,
        limit: 20,
        offset: 0,
        searchText: searchQuery.value,
        status: selectedStatus.value == 'All' ? null : selectedStatus.value,
      );
      searchSalesInvoices.value = response.salesInvoices;
      searchPosInvoices.value   = response.posInvoices;
    } catch (_) {
      Get.snackbar('Erreur', 'Impossible de chercher les factures');
    } finally {
      isSearching.value = false;
    }
  }
}