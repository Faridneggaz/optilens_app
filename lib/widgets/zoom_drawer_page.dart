import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:get/get.dart';

import '../core/theme/app_colors.dart';
import '../presentation/controllers/language_controller.dart';
import '../presentation/controllers/main_controller.dart';
import '../presentation/controllers/session_controller.dart';
import '../presentation/controllers/user_dashboard_controller.dart';
import '../views/client/dashboard_view.dart';
import '../views/client/invoice_view.dart';
import '../views/client/payment_view.dart';
import '../views/client/profile_view.dart';
import '../views/user/user_dashboard.dart';
import 'bottom_navbar.dart';
import 'drawer_screen.dart';

class ZoomDrawerPage extends StatelessWidget {
  const ZoomDrawerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();

    return Obx(() {
      if (session.isRestoring.value) {
        return const Scaffold(
          backgroundColor: AppColors.scaffoldAlt,
          body: Center(child: CircularProgressIndicator(color: Colors.teal)),
        );
      }

      final isUser = session.isUser.value;
      final drawerCtrl = session.zoomDrawerCtrl;

      void openPage(int i) {
        if (isUser) {
          Get.find<UserDashboardController>().setPage(i);
        } else {
          Get.find<MainController>().setPage(i);
        }
        drawerCtrl.close?.call();
      }

      return GetBuilder<LanguageController>(
        builder: (lang) => ZoomDrawer(
          controller: drawerCtrl,
          isRtl: lang.isRtl,
          menuScreen: DrawerScreen(
            onSelectPage: openPage,
            isUser: isUser,
          ),
          mainScreen: isUser ? UserDashboardPage() : _ClientShell(),
          borderRadius: 28,
          showShadow: true,
          angle: 0.0,
          drawerShadowsBackgroundColor: AppColors.drawerShadow,
          slideWidth: MediaQuery.of(context).size.width > 600
              ? 350.0
              : MediaQuery.of(context).size.width * 0.80,
          menuBackgroundColor: AppColors.scaffold,
        ),
      );
    });
  }
}

class _ClientShell extends StatelessWidget {
  _ClientShell();

  final MainController c = Get.find<MainController>();

  final List<Widget> _pages = [
    DashboardPage(),
    InvoicePage(),
    PaymentPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {
        c.handleBackPress();
      },
      child: Obx(() => Scaffold(
            body: _pages[c.selectedIndex.value],
            bottomNavigationBar: BottomNavBar(
              currentIndex: c.selectedIndex.value,
              onTap: c.setPage,
            ),
          )),
    );
  }
}
