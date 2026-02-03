import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import '../widgets/drawer_screen.dart';
import '../main.dart'; 
import '../domain/response/Customer.dart';
import '../views/user/user_dashboard.dart';

class ZoomDrawerPage extends StatefulWidget {
  final Customer? customer; // Requis pour MainPage
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

  void openPage(int index) {
    if (widget.isUser) {
      // Pilote la navigation interne du User
      _userPageKey.currentState?.setPage(index);
    } else {
      // Pilote la navigation interne du Client
      _mainPageKey.currentState?.setPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ZoomDrawer(
      controller: _drawerController,
      menuScreen: DrawerScreen(
        onSelectPage: openPage, 
        isUser: widget.isUser, // Transmet le rôle au menu
      ),
      mainScreen: widget.isUser
          ? UserDashboardPage(
              key: _userPageKey,
              userName: widget.userName ?? '',
              token: widget.token!,
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