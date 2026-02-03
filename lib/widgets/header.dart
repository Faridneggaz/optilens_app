import 'package:flutter/material.dart';
import 'logout_dialogue.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final dynamic customer;
  final String customerCode;
  final VoidCallback? onMenuTap; // ← AJOUTÉ

  const AppHeader({
    super.key,
    required this.title,
    required this.customer,
    required this.customerCode,
    this.onMenuTap, // ← AJOUTÉ
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black26,
      child: SizedBox(
        height: preferredSize.height,
        child: Stack(
          children: [
            Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color.fromRGBO(239, 67, 67, 1),
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.menu, size: 28),
                onSelected: (_) => LogoutDialog.show(context),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'logout', child: Text('Logout')),
                ],
              ),
            ),
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: InkWell(
                onTap: () {
                  if (onMenuTap != null) {
                    onMenuTap!(); // ← APPELLE LE CALLBACK
                  } else {
                    ZoomDrawer.of(context)?.toggle();
                  }
                },
                child: Center(
                  child: Image.asset(
                    'assets/images/optilensss.png',
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}