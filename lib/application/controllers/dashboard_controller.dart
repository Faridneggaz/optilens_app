import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/announcement_repository.dart';
import '../../domain/response/sales_invoice.dart';
import '../../domain/response/announcement.dart';
import 'session_controller.dart';

class DashboardController extends GetxController {
  final _invoiceRepo      = InvoiceRepository();
  final _announcementRepo = AnnouncementRepository();
  final _session          = Get.find<SessionController>();

  final invoices          = <SalesInvoice>[].obs;
  final announcements     = <Announcement>[].obs;
  final isInitialLoading  = true.obs;
  final isMoreLoading     = false.obs;
  final hasMore           = true.obs;

  int _offset = 0;
  static const int _limit = 5;
  late final ScrollController scrollController;

  @override
  void onInit() {
    super.onInit();
    scrollController = ScrollController();
    scrollController.addListener(_onScroll);
    loadInitialData();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent * 0.9) {
      if (!isMoreLoading.value && hasMore.value) fetchMoreAnnouncements();
    }
  }

  String get _customerCode => _session.customer.value?.code ?? '';

  Future<void> loadInitialData() async {
    _offset          = 0;
    hasMore.value    = true;
    isInitialLoading.value = true;
    await Future.wait([_fetchInvoices(), _fetchAnnouncements()]);
    isInitialLoading.value = false;
  }

  Future<void> _fetchInvoices() async {
    try {
      final r = await _invoiceRepo.fetchInvoices(_customerCode, limit: 5);
      invoices.value = r.sales_invoices;
    } catch (_) {}
  }

  Future<void> _fetchAnnouncements() async {
    try {
      final result = await _announcementRepo.fetchAnnouncements(
          _customerCode, limit: _limit, offset: 0);
      announcements.value = result;
      _offset             = _limit;
      if (result.length < _limit) hasMore.value = false;
    } catch (_) {}
  }

  Future<void> fetchMoreAnnouncements() async {
    isMoreLoading.value = true;
    try {
      final result = await _announcementRepo.fetchAnnouncements(
          _customerCode, limit: _limit, offset: _offset);
      if (result.isEmpty) {
        hasMore.value = false;
      } else {
        announcements.addAll(result);
        _offset += _limit;
        if (result.length < _limit) hasMore.value = false;
      }
    } catch (_) {
    } finally {
      isMoreLoading.value = false;
    }
  }
}
