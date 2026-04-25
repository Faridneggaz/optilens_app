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

  int _offset = 0;
  static const int _limit = 20;
  double _lastScrollOffset = 0;
  late final ScrollController scrollController;
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    scrollController = ScrollController()..addListener(_onScroll);
    fetchInvoices();
  }

  @override
  void onClose() {
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

  List<InvoiceItemData> get filteredSalesItems => salesInvoices
      .where((i) =>
          i.name.toLowerCase().contains(searchQuery.value.toLowerCase()) &&
          (selectedStatus.value == 'All' || i.status == selectedStatus.value))
      .map((i) => InvoiceItemData(
            title: i.name,
            ttc: i.outstanding_amount,
            price: i.grand_total,
            postingDate: i.posting_date,
            status: i.status,
          ))
      .toList();

  List<InvoiceItemData> get filteredPOSItems => posInvoices
      .where((i) =>
          i.name.toLowerCase().contains(searchQuery.value.toLowerCase()) &&
          (selectedStatus.value == 'All' || i.status == selectedStatus.value))
      .map((i) => InvoiceItemData(
            title: i.name,
            ttc: i.outstanding_amount,
            price: i.grand_total,
            postingDate: i.posting_date,
            status: i.status,
          ))
      .toList();

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
      );

      if (isLoadMore) {
        salesInvoices.addAll(response.sales_invoices);
        posInvoices.addAll(response.pos_invoices);
      } else {
        salesInvoices.value = response.sales_invoices;
        posInvoices.value   = response.pos_invoices;
      }

      if (response.sales_invoices.length < _limit &&
          response.pos_invoices.length < _limit) {
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
}