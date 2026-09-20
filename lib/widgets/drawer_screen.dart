import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/routes/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../presentation/controllers/language_controller.dart';
import '../presentation/controllers/session_controller.dart';

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
        backgroundColor: AppColors.scaffold,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 15),
                child: Image.asset('assets/images/optilensss.png', height: 100),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading:
                          const Icon(Icons.home, color: AppColors.menuTeal),
                      title: Text('nav_home'.tr),
                      onTap: () {
                        ZoomDrawer.of(context)?.close();
                        onSelectPage(0);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications,
                          color: AppColors.menuTeal),
                      title: Text('nav_notifications'.tr),
                      onTap: () {
                        ZoomDrawer.of(context)?.close();
                        Get.toNamed(AppRoutes.notifications);
                      },
                    ),
                    if (isUser)
                      ListTile(
                        leading: const Icon(Icons.checklist_rtl,
                            color: AppColors.menuTeal),
                        title: Text('nav_my_tasks'.tr),
                        onTap: () {
                          ZoomDrawer.of(context)?.close();
                          onSelectPage(5);
                        },
                      ),
                    if (isUser)
                      Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          leading: const Icon(Icons.inventory_2,
                              color: AppColors.menuTeal),
                          title: Text(
                            'nav_stock'.tr,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          iconColor: AppColors.menuTeal,
                          collapsedIconColor: AppColors.menuTeal,
                          childrenPadding: const EdgeInsetsDirectional.only(
                              start: 12, end: 8),
                          children: [
                            ListTile(
                              leading: const Icon(Icons.swap_horiz,
                                  color: AppColors.menuTeal),
                              title: Text('nav_stock_entries'.tr),
                              onTap: () {
                                ZoomDrawer.of(context)?.close();
                                onSelectPage(2);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.analytics_outlined,
                                  color: AppColors.menuTeal),
                              title: Text('nav_stock_summary'.tr),
                              onTap: () {
                                ZoomDrawer.of(context)?.close();
                                onSelectPage(4);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.assignment_outlined,
                                  color: AppColors.menuTeal),
                              title: Text('material_requests'.tr),
                              onTap: () {
                                ZoomDrawer.of(context)?.close();
                                onSelectPage(3);
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUser) ...[
                      const Divider(height: 1, color: AppColors.dividerMint),
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
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.language,
                            color: AppColors.menuTeal),
                        title: Text('website'.tr),
                        onTap: () =>
                            launchUrl(Uri.parse('https://jethings.com')),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.info_outline,
                            color: AppColors.menuTeal),
                        title: Text('app_joptic'.tr),
                        onTap: () {
                          ZoomDrawer.of(context)?.close();
                          Get.toNamed(AppRoutes.aboutJoptic);
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    InkWell(
                      onTap: () {
                        ZoomDrawer.of(context)?.close();
                        Get.find<SessionController>().logout();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.dangerSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout, color: AppColors.danger),
                            const SizedBox(width: 10),
                            Text(
                              'btn_logout'.tr,
                              style: const TextStyle(
                                color: AppColors.danger,
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
