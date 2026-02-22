import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../widgets/drawer_screen.dart';
import '../main.dart'; 
import '../domain/response/Customer.dart';
import '../views/user/user_dashboard.dart';
import '../views/client/login_view.dart'; 

class ZoomDrawerPage extends StatefulWidget {
  final Customer? customer;
  final bool isUser;
  final String? userName;
  final String? token;

  const ZoomDrawerPage({
    super.key,
    required this.isUser,
    this.customer,
    this.userName,
    this.token,
  });

  @override
  State<ZoomDrawerPage> createState() => _ZoomDrawerPageState();
}

class _ZoomDrawerPageState extends State<ZoomDrawerPage> {
  final GlobalKey<UserDashboardPageState> _userPageKey = GlobalKey();
  final GlobalKey<MainPageState> _mainPageKey = GlobalKey();
  final ZoomDrawerController _drawerController = ZoomDrawerController();

  @override
  void initState() {
    super.initState();
    // ... vos logs de debug ...
  }

  // 3. Ajouter la fonction de déconnexion ici
  Future<void> _handleLogout() async {
    // Vider les préférences (Token, User info, etc.)
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    // Rediriger vers la page de Login et effacer l'historique de navigation
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()), // Assurez-vous que LoginPage est bien importé
      (route) => false,
    );
  }

  void openPage(int index) {
    if (widget.isUser) {
      _userPageKey.currentState?.setPage(index);
    } else {
      _mainPageKey.currentState?.setPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ZoomDrawer(
      controller: _drawerController,
      menuScreen: DrawerScreen(
        onSelectPage: openPage, 
        isUser: widget.isUser,
        onLogout: _handleLogout, // Passer la fonction de déconnexion au DrawerScreen
      ),
      mainScreen: widget.isUser
          ? UserDashboardPage(
              key: _userPageKey,
              userName: widget.userName ?? '',
              token: widget.token ?? '',
              drawerController: _drawerController, 
            )
          : MainPage(
              key: _mainPageKey, 
              customer: widget.customer!, 
            ),
      borderRadius: 28,
      showShadow: true,
      angle: 0.0,
      drawerShadowsBackgroundColor: const Color.fromARGB(255, 47, 142, 138),
      slideWidth: MediaQuery.of(context).size.width * 0.80,
      menuBackgroundColor: Colors.white,
    );
  }
}