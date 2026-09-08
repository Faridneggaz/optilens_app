import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/header.dart';
import '../../../application/controllers/user_dashboard_controller.dart';
import '../../../application/controllers/language_controller.dart';
import '../../../application/controllers/session_controller.dart';
import '../../utils/responsive_utils.dart';
import '../../../domain/response/stock_entry.dart';
import 'material_request_page.dart';

class UserDashboardPage extends StatelessWidget {
  UserDashboardPage({super.key});

  final UserDashboardController c = Get.find<UserDashboardController>();
  final SessionController session = Get.find<SessionController>();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LanguageController>(
      builder: (_) => Obx(() {
        switch (c.selectedPageIndex.value) {
          case 1:  return _buildNotifications();
          case 2:  return _buildStockManagement(context);
          case 3:  return const MaterialRequestPage();
          default: return _buildHome();
        }
      }),
    );
  }

  Widget _buildHome() {
    final userName = session.userName.value;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 255, 254),
      body: Column(children: [
        AppHeader(
            title: 'nav_home'.tr,
            customer: null,
            customerCode: '',
            onMenuTap: () =>
                Get.find<SessionController>().zoomDrawerCtrl.toggle?.call()),
        Expanded(
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.person_pin,
                  size: 100, color: Color(0xFF3BADA2)),
              const SizedBox(height: 20),
              Text('${'welcome_user'.tr}$userName',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2837))),
              Text('select_service'.tr,
                  style: const TextStyle(color: Colors.grey)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildNotifications() {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 255, 254),
      body: Column(children: [
        AppHeader(
            title: 'notifications_title'.tr,
            customer: null,
            customerCode: '',
            onMenuTap: () =>
                Get.find<SessionController>().zoomDrawerCtrl.toggle?.call()),
        Expanded(child: Center(child: Text('no_notifications'.tr))),
      ]),
    );
  }

  Widget _buildStockManagement(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 255, 254),
      body: Column(children: [
        AppHeader(
            title: '',
            customer: null,
            customerCode: '',
            onMenuTap: () =>
                Get.find<SessionController>().zoomDrawerCtrl.toggle?.call()),

        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: _buildSearchBar(),
          ),
        ),

        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Obx(() => RefreshIndicator(
                    onRefresh: c.onRefresh,
                    color: Colors.teal,
                    child: (c.isLoading.value && !c.isLoadingMore.value) || c.isSearching.value
                        ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                        : c.filteredEntries.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  const SizedBox(height: 100),
                                  Center(
                                      child: Text('no_stock_entries'.tr)),
                                ],
                              )
                            : ResponsiveLayout.isMobile(context)
                                ? _buildList()
                                : _buildGrid(context),
                  )),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 20),
      itemCount: c.filteredEntries.length + 1,
      itemBuilder: (context, i) => i < c.filteredEntries.length
          ? _buildStockItem(c.filteredEntries[i])
          : _buildLoadMoreButton(),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(children: [
        Wrap(
          alignment: WrapAlignment.center,
          children: List.generate(c.filteredEntries.length, (i) {
            return SizedBox(
              width: ResponsiveLayout.isDesktop(context) ? 450 : 350,
              child: _buildStockItem(c.filteredEntries[i]),
            );
          }),
        ),
        const SizedBox(height: 20),
        _buildLoadMoreButton(),
      ]),
    );
  }

  Widget _buildLoadMoreButton() {
    if (c.searchQuery.value.isNotEmpty || c.isSearching.value) {
      return const SizedBox.shrink();
    }
    if (!c.hasMore.value && c.stockEntries.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
            child: Text('all_entries_loaded'.tr,
                style: const TextStyle(color: Colors.grey))),
      );
    }
    if (c.isLoadingMore.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (c.hasMore.value && c.stockEntries.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ElevatedButton(
          onPressed: c.onLoadMore,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 247, 255, 253),
            foregroundColor:  Colors.teal,
            elevation:        0,
            side: const BorderSide(color: Colors.teal),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: Text('load_more'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStockItem(StockEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => c.navigateToStockEntry(entry.name),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('stock_entry_label'.tr,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color.fromRGBO(31, 40, 55, 1))),
                  ),
                  const SizedBox(width: 8),
                  Text(_translateStatus(entry.status),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(entry.status))),
                ],
              ),
              const SizedBox(height: 4),
              Text(entry.name,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color.fromRGBO(31, 40, 55, 1))),
              const SizedBox(height: 4),
              Text(entry.postingDate,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.teal;
      case 'pending':  return Colors.orange;
      case 'draft':    return Colors.grey;
      default:         return Colors.black;
    }
  }

  String _translateStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':   return 'filter_pending'.tr;
      case 'approved':  return 'filter_approved'.tr;
      case 'draft':     return 'filter_draft'.tr;
      default:          return status ?? '';
    }
  }
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 247, 255, 253),
                                  borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: c.searchController,
                onChanged: (v) {
                  c.searchQuery.value = v;
                },
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'search_stock_hint'.tr,
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                  prefixIcon: Obx(() => Icon(
                    c.isSearching.value 
                      ? Icons.hourglass_empty 
                      : Icons.search,
                    color: Colors.black54,
                    size: 24,
                  )),
                  suffixIcon: Obx(() => c.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                        onPressed: () {
                          c.searchController.clear();
                          c.searchQuery.value = '';
                        },
                      )
                    : const SizedBox.shrink(),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 48,
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 247, 255, 253),
                                  borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: Obx(() => DropdownButton<String>(
                dropdownColor: Colors.white,
                value: c.selectedStatus.value,
              icon: const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.filter_list, 
                           color: Colors.black87, 
                           size: 24),
              ),
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              items: [
                DropdownMenuItem(value: 'All',      child: Text('filter_all'.tr)),
                DropdownMenuItem(value: 'Draft',    child: Text('filter_draft'.tr)),
                DropdownMenuItem(value: 'Approved', child: Text('filter_approved'.tr)),
                DropdownMenuItem(value: 'Rejected', child: Text('Rejected'.tr)),
              ],
              onChanged: (v) {
                if (v != null) c.selectedStatus.value = v;
              },
            )),
          ),
          ),
        ],
      ),
    );
  }
}

