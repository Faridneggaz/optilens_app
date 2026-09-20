import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/header.dart';
import '../../../presentation/controllers/user_dashboard_controller.dart';
import '../../../presentation/controllers/language_controller.dart';
import '../../../presentation/controllers/session_controller.dart';
import 'material_request_page.dart';
import 'stock_entry_list_page.dart';
import 'stock_summary_page.dart';
import 'tasks_page.dart';
import '../../core/theme/app_colors.dart';

class UserDashboardPage extends StatelessWidget {
  UserDashboardPage({super.key});

  final UserDashboardController c = Get.find<UserDashboardController>();
  final SessionController session = Get.find<SessionController>();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LanguageController>(
      builder: (_) => Obx(() {
        switch (c.selectedPageIndex.value) {
          case 1:
            return _buildNotifications();
          case 2:
            return const StockEntryListPage();
          case 3:
            return const MaterialRequestPage();
          case 4:
            return const StockSummaryPage();
          case 5:
            return const TasksPage();
          default:
            return _buildHome();
        }
      }),
    );
  }

  Widget _buildHome() {
    final userName = session.userName.value;
    return Scaffold(
      backgroundColor: AppColors.scaffoldTint,
      body: Column(children: [
        AppHeader(
            title: 'nav_home'.tr,
            customer: null,
            customerCode: '',
            onMenuTap: () =>
                Get.find<SessionController>().openDrawer()),
        Expanded(
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.person_pin,
                  size: 100, color: AppColors.menuTeal),
              const SizedBox(height: 20),
              Text('${'welcome_user'.tr}$userName',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink)),
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
      backgroundColor: AppColors.scaffoldTint,
      body: Column(children: [
        AppHeader(
            title: 'notifications_title'.tr,
            customer: null,
            customerCode: '',
            onMenuTap: () =>
                Get.find<SessionController>().openDrawer()),
        Expanded(child: Center(child: Text('no_notifications'.tr))),
      ]),
    );
  }
}
