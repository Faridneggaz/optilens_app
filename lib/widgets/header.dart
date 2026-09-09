import 'package:flutter/material.dart';
import 'logout_dialogue.dart';
import 'language_selector_widget.dart';
import 'package:get/get.dart';
import '../application/controllers/session_controller.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final dynamic customer;
  final String customerCode;
  final VoidCallback? onMenuTap;

  const AppHeader({
    super.key,
    required this.title,
    required this.customer,
    required this.customerCode,
    this.onMenuTap, 
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black26,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo — on left in LTR, on right in RTL (auto by Directionality)
                GestureDetector(
                  onTap: () {
                    Get.find<SessionController>().zoomDrawerCtrl.toggle?.call();
                  },
                  child: Image.asset(
                    'assets/images/optilensss.png',
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                ),

                // Centered title
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1F2837),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                // Action icons — on right in LTR, on left in RTL
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.language, size: 22),
                      tooltip: 'language_tooltip'.tr,
                      onPressed: LanguageSelectorWidget.show,
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.menu, size: 28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      elevation: 8,
                      offset: const Offset(0, 40),
                      onSelected: (_) => LogoutDialog.show(context),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.logout, color: Colors.redAccent, size: 22),
                              const SizedBox(width: 12),
                              Text(
                                'btn_logout'.tr,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}