import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/header.dart';
import '../../utils/announcement_utils.dart';
import '../../../application/controllers/dashboard_controller.dart';
import '../../../application/controllers/language_controller.dart';
import '../../../application/controllers/session_controller.dart';
import '../../../app/routes/app_routes.dart';

class DashboardPage extends StatelessWidget {
  DashboardPage({super.key});

  final DashboardController c = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    final customer = Get.find<SessionController>().customer.value!;

    // GetBuilder<LanguageController> force la reconstruction du Scaffold entier
    // à chaque changement de langue (update() est appelé dans changeLanguage()).
    return GetBuilder<LanguageController>(
      builder: (_) => Scaffold(
        backgroundColor: const Color.fromARGB(255, 246, 255, 253),
        body: Column(
          children: [
            AppHeader(
              title: '',
              customer: customer,
              customerCode: customer.code,
            ),
            Expanded(
              child: Obx(() => RefreshIndicator(
                    onRefresh: c.loadInitialData,
                    color: const Color.fromARGB(255, 0, 167, 155),
                    child: c.isInitialLoading.value && c.announcements.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : ListView(
                            controller: c.scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 30),
                            children: [
                              const SizedBox(height: 20),

                              // Carte solde impayé
                              _buildOutstandingCard(customer),

                              const SizedBox(height: 25),

                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text('dashboard'.tr,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1F2837))),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              _simpleCard('price_list'.tr, customer.priceList),

                              const SizedBox(height: 25),

                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text('announcements'.tr,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1F2837))),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              if (c.announcements.isEmpty)
                                Center(
                                    child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Text('no_announcements'.tr),
                                ))
                              else
                                ...c.announcements.map(
                                  (ann) => AnnouncementCard(
                                    announcement: ann,
                                    onTap: () => Get.toNamed(
                                        AppRoutes.announcementDetail,
                                        arguments: ann),
                                  ),
                                ),

                              if (c.isMoreLoading.value)
                                const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                                ),

                              if (!c.hasMore.value && c.announcements.isNotEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Text('all_announcements_loaded'.tr,
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 12)),
                                  ),
                                ),
                            ],
                          ),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutstandingCard(customer) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(221, 244, 242, 1.0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color.fromRGBO(0, 168, 156, 1), width: 4),
      ),
      child: Column(
        children: [
          Text('outstanding_amount'.tr,
              style: const TextStyle(
                  fontSize: 18,
                  color: Colors.teal,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            '${customer.debt.toStringAsFixed(2)} DA',
            style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1F2837)),
          ),
        ],
      ),
    );
  }

  Widget _simpleCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2837))),
          ),
          Text(value,
              style: const TextStyle(
                  color: Colors.teal, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}