import 'package:flutter/material.dart';
import 'logout_dialogue.dart';
import 'language_selector_widget.dart';
import 'package:get/get.dart';
import '../core/theme/app_colors.dart';
import '../presentation/controllers/session_controller.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final dynamic customer;
  final String customerCode;
  final VoidCallback? onMenuTap;
  final String? subtitle;

  const AppHeader({
    super.key,
    required this.title,
    required this.customer,
    required this.customerCode,
    this.onMenuTap,
    this.subtitle,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(subtitle == null || subtitle!.isEmpty ? 72 : 88);

  void _handleLogoTap() {
    if (onMenuTap != null) {
      onMenuTap!();
      return;
    }
    Get.find<SessionController>().openDrawer();
  }

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
                InkWell(
                  onTap: _handleLogoTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: Image.asset(
                      'assets/images/optilensss.png',
                      height: 30,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Text(
                            subtitle!,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
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
                              const Icon(Icons.logout,
                                  color: Colors.redAccent, size: 22),
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
