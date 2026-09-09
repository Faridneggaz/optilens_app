import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bottom_navbar.dart';
import '../views/client/dashboard_view.dart';
import '../views/client/invoice_view.dart';
import '../views/client/payment_view.dart';
import '../views/client/profile_view.dart';
import '../views/user/user_dashboard.dart';
import '../application/controllers/session_controller.dart';
import '../application/controllers/main_controller.dart';
import '../application/controllers/language_controller.dart';
import '../application/controllers/user_dashboard_controller.dart';
import '../app/routes/app_routes.dart';

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

      return GetBuilder<LanguageController>(
        builder: (lang) => ZoomDrawer(
          controller:   drawerCtrl,
          isRtl:        lang.isRtl,
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
          menuBackgroundColor: const Color.fromARGB(255, 247, 255, 253),
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
    const primaryColor = Color(0xFF3BADA2);

    return GetBuilder<LanguageController>(
      builder: (_) => Scaffold(
        backgroundColor: const Color.fromARGB(255, 247, 255, 253),
        body: SafeArea(
          child: Column(
            children: [
              // 1. Logo Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 15),
                child: Image.asset('assets/images/optilensss.png', height: 100),
              ),

              // 2. Menu Principal (ListView)
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.home, color: primaryColor),
                      title: Text('nav_home'.tr),
                      onTap: () {
                        ZoomDrawer.of(context)?.close();
                        onSelectPage(0);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications, color: primaryColor),
                      title: Text('nav_notifications'.tr),
                      onTap: () {
                        ZoomDrawer.of(context)?.close();
                        Get.toNamed(AppRoutes.notifications);
                      },
                    ),
                      if (isUser)
                        ListTile(
                          leading: const Icon(Icons.inventory_2, color: primaryColor),
                          title: Text('nav_stock'.tr),
                          onTap: () {
                            ZoomDrawer.of(context)?.close();
                            onSelectPage(2);
                          },
                        ),
                      if (isUser)
                        ListTile(
                          leading: const Icon(Icons.assignment_outlined, color: primaryColor),
                          title: Text('material_requests'.tr),
                          onTap: () {
                            ZoomDrawer.of(context)?.close();
                            onSelectPage(3);
                          },
                        ),
                  ],
                ),
              ),

              // 3. Section Basse (J-Optic & Logout)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECTION J-OPTIC PLACÃ‰E EN BAS ---
                    if (!isUser) ...[
                      const Divider(height: 1, color: Color(0xFFE8F3F0)),
                      const SizedBox(height: 15),
                      Text(
                        'about_joptic_section'.tr,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Lien Site Web
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.language, color: primaryColor),
                        title: Text('website'.tr),
                        onTap: () => launchUrl(Uri.parse('https://jethings.com')),
                      ),
                      // Lien App
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.info_outline, color: primaryColor),
                        title: Text('app_joptic'.tr),
                        onTap: () {
                          ZoomDrawer.of(context)?.close();
                          Get.toNamed(AppRoutes.aboutJoptic);
                        },
                      ),
                      const SizedBox(height: 10),
                    ],

                    // --- BOUTON DÃ‰CONNEXION ---
                    InkWell(
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout, color: Color.fromARGB(255, 223, 54, 38)),
                            const SizedBox(width: 10),
                            Text(
                              'btn_logout'.tr,
                              style: const TextStyle(
                                color: Color.fromARGB(255, 223, 54, 38),
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: 'powered_by'.tr,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Jethings',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

