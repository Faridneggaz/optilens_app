import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:get/get.dart';
import 'bottom_navbar.dart';
import '../views/client/dashboard_view.dart';
import '../views/client/invoice_view.dart';
import '../views/client/payment_view.dart';
import '../views/client/profil_view.dart';
import '../views/user/user_dashboard.dart';
import '../application/controllers/session_controller.dart';
import '../application/controllers/main_controller.dart';
import '../application/controllers/user_dashboard_controller.dart';

class ZoomDrawerPage extends StatelessWidget {
  const ZoomDrawerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();

    return Obx(() {
      if (session.isRestoring.value) {
        return const Scaffold(
          backgroundColor: Color.fromARGB(255, 246, 255, 253),
          body: Center(child: CircularProgressIndicator(color: Colors.teal)),
        );
      }

      final isUser     = session.isUser.value;
      final drawerCtrl = session.zoomDrawerCtrl;

      void openPage(int i) {
        if (isUser) {
          Get.find<UserDashboardController>().setPage(i);
        } else {
          Get.find<MainController>().setPage(i);
        }
        drawerCtrl.close?.call();
      }

      return ZoomDrawer(
        controller:   drawerCtrl,
        menuScreen:   DrawerScreen(
          onSelectPage: openPage,
          isUser:       isUser,
        ),
        mainScreen:   isUser ? UserDashboardPage() : _ClientShell(),
        borderRadius: 28,
        showShadow:   true,
        angle:        0.0,
        drawerShadowsBackgroundColor:
            const Color.fromARGB(255, 47, 142, 138),
        slideWidth: MediaQuery.of(context).size.width > 600
            ? 350.0
            : MediaQuery.of(context).size.width * 0.80,
        menuBackgroundColor: Colors.white,
      );
    });
  }
}

/// Client mode: bottom-nav shell (4 pages).
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
      onPopInvokedWithResult: (_, __) { c.handleBackPress(); },
      child: Obx(() => Scaffold(
            body: _pages[c.selectedIndex.value],
            bottomNavigationBar: BottomNavBar(
              currentIndex: c.selectedIndex.value,
              onTap:        c.setPage,
            ),
          )),
    );
  }
}

/// The slide-out drawer.
class DrawerScreen extends StatelessWidget {
  final Function(int) onSelectPage;
  final bool isUser;

  const DrawerScreen({
    super.key,
    required this.onSelectPage,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 255, 255),
      body: SafeArea(
        child: Column(children: [
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 15),
            child: Image.asset('assets/images/optilensss.png', height: 100),
          ),

          Column(children: [
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFF3BADA2)),
              title: const Text('Home'),
              onTap:  () => onSelectPage(0),
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Color(0xFF3BADA2)),
              title: const Text('Notifications'),
              onTap:  () => onSelectPage(1),
            ),
            if (isUser)
              ListTile(
                leading: const Icon(Icons.inventory_2, color: Color(0xFF3BADA2)),
                title: const Text('Stock'),
                onTap:  () => onSelectPage(2),
              ),
          ]),

          const Spacer(),

          // Logout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InkWell(
              onTap: () {
                ZoomDrawer.of(context)?.close();
                Get.find<SessionController>().logout();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 226, 227),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.logout,
                      color: Color.fromARGB(255, 223, 54, 38)),
                  SizedBox(width: 10),
                  Text('Log Out',
                      style: TextStyle(
                          color: Color.fromARGB(255, 223, 54, 38),
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ]),
              ),
            ),
          ),

          const SizedBox(height: 25),

          Text.rich(const TextSpan(
            text: 'Powered by ',
            style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w600),
            children: [
              TextSpan(
                  text: 'Jethings',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black54)),
            ],
          )),

          const SizedBox(height: 30),
        ]),
      ),
    );
  }
}