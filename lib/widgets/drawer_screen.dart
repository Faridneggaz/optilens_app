import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:get/get.dart';
import '../application/controllers/language_controller.dart';
import '../application/controllers/session_controller.dart';
import '../app/routes/app_routes.dart';

/// The slide-out drawer. Removed onLogout callback — uses SessionController
/// directly. Removed onSelectPage callback — caller passes it in (ZoomDrawerPage).
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
    return GetBuilder<LanguageController>(
      builder: (_) => Scaffold(
        backgroundColor: const Color.fromARGB(255, 254, 255, 255),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    // Logo
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 15),
                      child: Image.asset('assets/images/optilensss.png', height: 100),
                    ),

                    // Menu items
                    Column(children: [
                      ListTile(
                        leading: const Icon(Icons.home, color: Color(0xFF3BADA2)),
                        title: Text('nav_home'.tr),
                        onTap: () {
                          ZoomDrawer.of(context)?.close();
                          onSelectPage(0);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.notifications,
                            color: Color(0xFF3BADA2)),
                        title: Text('nav_notifications'.tr),
                        onTap: () {
                          ZoomDrawer.of(context)?.close();
                          Get.toNamed(AppRoutes.notifications);
                        },
                      ),
                      if (isUser)
                        ListTile(
                          leading: const Icon(Icons.inventory_2,
                              color: Color(0xFF3BADA2)),
                          title: Text('nav_stock'.tr),
                          onTap: () {
                            ZoomDrawer.of(context)?.close();
                            onSelectPage(2);
                          },
                        ),
                    ]),

                    const Spacer(),

                    // Logout button
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.logout,
                                  color: Color.fromARGB(255, 223, 54, 38)),
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
                    ),

                    const SizedBox(height: 25),

                    // Footer
                    Text.rich(
                      TextSpan(
                        text: 'powered_by'.tr,
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                        children: const [
                          TextSpan(
                            text: 'Jethings',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black54),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
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