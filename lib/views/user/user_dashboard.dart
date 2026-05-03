import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/header.dart';
import '../../../application/controllers/user_dashboard_controller.dart';
import '../../../application/controllers/session_controller.dart';
import '../../utils/responsive_utils.dart';
import '../../../domain/response/stock_entry.dart';

class UserDashboardPage extends StatelessWidget {
  UserDashboardPage({super.key});

  final UserDashboardController c = Get.find<UserDashboardController>();
  final SessionController session = Get.find<SessionController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (c.selectedPageIndex.value) {
        case 1:  return _buildNotifications();
        case 2:  return _buildStockManagement(context);
        default: return _buildHome();
      }
    });
  }

  Widget _buildHome() {
    final userName = session.userName.value;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 255, 254),
      body: Column(children: [
        AppHeader(
            title: 'Home',
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
              Text('Welcome, $userName',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2837))),
              const Text('Select a service from the menu to start',
                  style: TextStyle(color: Colors.grey)),
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
            title: 'Notifications',
            customer: null,
            customerCode: '',
            onMenuTap: () =>
                Get.find<SessionController>().zoomDrawerCtrl.toggle?.call()),
        const Expanded(child: Center(child: Text('No new notifications'))),
      ]),
    );
  }

  Widget _buildStockManagement(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 255, 254),
      body: Column(children: [
        AppHeader(
            title: 'Stock',
            customer: null,
            customerCode: '',
            onMenuTap: () =>
                Get.find<SessionController>().zoomDrawerCtrl.toggle?.call()),

        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Obx(() => StockFilterBar(
                  selectedStatus:  c.selectedStatus.value,
                  onSearchChanged: (v) => c.searchQuery.value = v,
                  onStatusChanged: (v) {
                    if (v != null) c.selectedStatus.value = v;
                  },
                )),
          ),
        ),

        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Obx(() => RefreshIndicator(
                    onRefresh: c.onRefresh,
                    color: Colors.teal,
                    child: c.isLoading.value && !c.isLoadingMore.value
                        ? const Center(child: CircularProgressIndicator())
                        : c.filteredEntries.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 100),
                                  Center(
                                      child: Text('No stock entries found')),
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
    if (c.searchQuery.value.isNotEmpty || c.selectedStatus.value != 'All') {
      return const SizedBox.shrink();
    }
    if (!c.hasMore.value && c.stockEntries.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
            child: Text('All entries loaded',
                style: TextStyle(color: Colors.grey))),
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
            backgroundColor:  Colors.white,
            foregroundColor:  Colors.teal,
            elevation:        0,
            side: const BorderSide(color: Colors.teal),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Load More (20)',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stock Entry : ${entry.name}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color.fromRGBO(31, 40, 55, 1))),
                    const SizedBox(height: 4),
                    Text(entry.postingDate,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13)),
                  ]),
            ),
            Text(entry.status,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(entry.status))),
          ]),
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
}

// ── StockFilterBar (kept co-located with UserDashboardPage) ──────────────────

class StockFilterBar extends StatelessWidget {
  final void Function(String)  onSearchChanged;
  final void Function(String?) onStatusChanged;
  final String selectedStatus;

  const StockFilterBar({
    super.key,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.selectedStatus,
  });

  @override
  Widget build(BuildContext context) {
    final c = Get.find<UserDashboardController>();

    return Container(
      color: const Color.fromARGB(255, 247, 255, 254),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade100),
            ),
            child: TextField(
              controller: c.searchController,
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Search MAT-STE...',
                prefixIcon: Icon(Icons.search, color: Colors.teal),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal.shade100),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              icon:  const Icon(Icons.filter_list, color: Colors.teal),
              value: selectedStatus,
              items: ['All', 'Approved', 'Pending', 'Draft']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: onStatusChanged,
            ),
          ),
        ),
      ]),
    );
  }
}