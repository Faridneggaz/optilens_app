import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/header.dart';
import '../../utils/invoice_utils.dart';
import '../../../presentation/controllers/invoice_controller.dart';
import '../../../presentation/controllers/language_controller.dart';
import '../../../app/routes/app_routes.dart';
import '../../widgets/client_session_gate.dart';
import '../../core/theme/app_colors.dart';

class InvoicePage extends StatelessWidget {
  InvoicePage({super.key});

  final InvoiceController c = Get.find<InvoiceController>();

  @override
  Widget build(BuildContext context) {
    return ClientSessionGate(
      builder: (customer) => GetBuilder<LanguageController>(
      builder: (_) => Scaffold(
        backgroundColor: const Color.fromRGBO(247, 255, 253, 1),
        body: Obx(() => Column(
            children: [
              AppHeader(
                  title: '',
                  customer: customer,
                  customerCode: customer.code),

              const SizedBox(height: 12),

              // Collapsible header with stats
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: c.isHeaderVisible.value ? null : 0,
                curve: Curves.easeInOut,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(245, 235, 234, 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('outstanding_amount'.tr,
                                     style: const TextStyle(
                                         fontSize: 18,
                                         color: Color.fromRGBO(238, 33, 33, 1),
                                         fontWeight: FontWeight.w900)),
                                const SizedBox(height: 8),
                                Text(
                                  '${customer.debt.toStringAsFixed(2)} DA',
                                  style: const TextStyle(
                                      fontSize: 30,
                                      color:
                                          Color.fromRGBO(31, 40, 55, 1),
                                      fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(
                                    255, 239, 69, 68),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.credit_card,
                                  size: 30,
                                  color: AppColors.scaffold),
                            ),
                          ],
                        ),
                      ),
                      _buildTabs(),
                      const SizedBox(height: 10),
                      _buildSearchBar(),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  color: const Color.fromARGB(255, 252, 253, 253),
                  child: RefreshIndicator(
                    onRefresh:  c.onRefresh,
                    color: AppColors.primary,
                    child: (c.isLoading.value && !c.isLoadingMore.value) || c.isSearching.value
                        ? const Center(
                            child: CircularProgressIndicator(color: AppColors.primary))
                        : SingleChildScrollView(
                            controller: c.scrollController,
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              children: [
                                _buildTabContent(),

                                // Load-more button
                                if (c.hasMore.value &&
                                    (c.salesInvoices.isNotEmpty ||
                                        c.posInvoices.isNotEmpty) && c.searchQuery.value.isEmpty && !c.isSearching.value)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20, horizontal: 16),
                                    child: c.isLoadingMore.value
                                        ? const Center(
                                            child:
                                                CircularProgressIndicator())
                                        : SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: c.onLoadMore,
                                              style: ElevatedButton
                                                  .styleFrom(
                                                backgroundColor: AppColors.scaffold,
                                                foregroundColor:
                                                    const Color
                                                        .fromARGB(255,
                                                        0, 167, 155),
                                                elevation: 0,
                                                side: const BorderSide(
                                                    color: Color.fromARGB(
                                                        255, 0, 167, 155)),
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    vertical: 12),
                                                shape:
                                                    RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(10),
                                                ),
                                              ),
                                             child: Text('load_more'.tr,
                                                 style: const TextStyle(
                                                     fontWeight: FontWeight.bold,
                                                     fontSize: 16)),
                                            ),
                                          ),
                                  ),

                                if (!c.hasMore.value &&
                                    (c.salesInvoices.isNotEmpty ||
                                        c.posInvoices.isNotEmpty))
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Text('all_invoices_loaded'.tr,
                                        style: const TextStyle(
                                            color: Colors.grey)),
                                  ),

                                if (c.salesInvoices.isEmpty &&
                                    c.posInvoices.isEmpty &&
                                    !c.isLoading.value)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 50),
                                    child: Center(
                                        child: Text('no_invoices'.tr)),
                                  ),

                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ],
          )),
      ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: const Color(0xFFE6F7F4),
          borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          _tabButton('tab_sales_invoices'.tr, 0),
          _tabButton('tab_pos_invoices'.tr,   1),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () => c.selectedTab.value = index,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: c.selectedTab.value == index
                ? Colors.white
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.selectedTab.value == index
                  ? AppColors.primary
                  : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    final items =
        c.selectedTab.value == 0 ? c.filteredSalesItems : c.filteredPOSItems;
    final type = c.selectedTab.value == 0 ? 'sales' : 'pos';

    return InvoiceList(
      invoiceType: type,
      items: items,
      onInvoiceTap: (item) => Get.toNamed(
        AppRoutes.invoiceDetail,
        arguments: {'invoiceName': item.title},
      ),
    );
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
                color: AppColors.scaffold,
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
                  hintText: 'search_invoice_hint'.tr,
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
              color: AppColors.scaffold,
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
                DropdownMenuItem(value: 'All',     child: Text('filter_all'.tr)),
                DropdownMenuItem(value: 'Unpaid',  child: Text('unpaid'.tr)),
                DropdownMenuItem(value: 'Paid',    child: Text('filter_paid'.tr)),
                DropdownMenuItem(value: 'Overdue', child: Text('filter_overdue'.tr)),
                DropdownMenuItem(value: 'Return',  child: Text('Return'.tr)),
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


