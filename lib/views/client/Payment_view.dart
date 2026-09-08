import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/header.dart';
import '../../utils/payment_utils.dart';
import '../../../application/controllers/language_controller.dart';
import '../../../application/controllers/payment_controller.dart';
import '../../../application/controllers/session_controller.dart';

class PaymentPage extends StatelessWidget {
  PaymentPage({super.key});

  final PaymentController c = Get.find<PaymentController>();

  @override
  Widget build(BuildContext context) {
    final customer = Get.find<SessionController>().customer.value!;

    return GetBuilder<LanguageController>(
      builder: (_) => Scaffold(
        backgroundColor: const Color.fromRGBO(247, 255, 253, 1),
        body: Column(
          children: [
            AppHeader(
                title: '',
                customer: customer,
                customerCode: customer.code),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Historique des paiements',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2837),
                ),
              ),
            ),
            _buildSearchBar(),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                if (c.isLoading.value && !c.isLoadingMore.value) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF00A79B)));
                }
                if (c.isSearching.value) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF00A79B)));
                }
                if (c.displayPayments.isEmpty) {
                  return Center(child: Text('no_payments'.tr));
                }
                return RefreshIndicator(
                  onRefresh: c.onRefresh,
                  color: const Color.fromARGB(255, 0, 167, 155),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        PaymentList(
                          globalTitle: '',
                          items: c.displayPayments,
                        ),

                        // Load More
                        if (c.hasMore.value && c.searchQuery.value.isEmpty && !c.isSearching.value)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 20, horizontal: 16),
                            child: c.isLoadingMore.value
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: c.onLoadMore,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(255, 247, 255, 253),
                                        foregroundColor: const Color.fromARGB(
                                            255, 0, 167, 155),
                                        elevation: 0,
                                        side: const BorderSide(
                                            color: Color.fromARGB(
                                                255, 0, 167, 155)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        'load_more'.tr,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                    ),
                                  ),
                          ),

                        if (!c.hasMore.value && c.searchQuery.value.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text('all_payments_loaded'.tr,
                                style:
                                    const TextStyle(color: Colors.grey)),
                          ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
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
                  hintText: 'search_payment_hint'.tr,
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
        ],
      ),
    );
  }
}


