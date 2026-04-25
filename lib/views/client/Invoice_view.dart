import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/header.dart';
import '../../widgets/invoice_filter_bar.dart';
import '../../utils/invoice_utils.dart';
import '../../../application/controllers/invoice_controller.dart';
import '../../../application/controllers/session_controller.dart';
import '../../../app/routes/app_routes.dart';

class InvoicePage extends StatelessWidget {
  InvoicePage({super.key});

  final InvoiceController c = Get.find<InvoiceController>();

  @override
  Widget build(BuildContext context) {
    final customer = Get.find<SessionController>().customer.value!;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 255, 253, 1),
      body: Obx(() => Column(
            children: [
              AppHeader(
                  title: '',
                  customer: customer,
                  customerCode: customer.code),

              InvoiceFilterBar(
                selectedStatus:  c.selectedStatus.value,
                onSearchChanged: (v) => c.searchQuery.value = v,
                onStatusChanged: (v) {
                  if (v != null) c.selectedStatus.value = v;
                },
              ),

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
                                const Text('Outstanding Amount',
                                    style: TextStyle(
                                        fontSize: 18,
                                        color:
                                            Color.fromRGBO(238, 33, 33, 1),
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
                                  color: Color.fromRGBO(254, 255, 255, 1)),
                            ),
                          ],
                        ),
                      ),
                      _buildTabs(),
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
                    color: const Color.fromARGB(255, 0, 167, 155),
                    child: c.isLoading.value && !c.isLoadingMore.value
                        ? const Center(
                            child: CircularProgressIndicator())
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
                                        c.posInvoices.isNotEmpty))
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
                                                backgroundColor:
                                                    Colors.white,
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
                                              child: const Text(
                                                  'Load More (20)',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16)),
                                            ),
                                          ),
                                  ),

                                if (!c.hasMore.value &&
                                    (c.salesInvoices.isNotEmpty ||
                                        c.posInvoices.isNotEmpty))
                                  const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Text('All invoices loaded',
                                        style: TextStyle(
                                            color: Colors.grey)),
                                  ),

                                if (c.salesInvoices.isEmpty &&
                                    c.posInvoices.isEmpty &&
                                    !c.isLoading.value)
                                  const Padding(
                                    padding:
                                        EdgeInsets.only(top: 50),
                                    child: Center(
                                        child: Text(
                                            'Aucune facture trouvée')),
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
          _tabButton('Sales Invoices', 0),
          _tabButton('POS Invoices',   1),
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
                  ? const Color.fromARGB(255, 0, 167, 155)
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
}