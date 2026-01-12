import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import '../widgets/drawer_screen.dart';
import '../main.dart';
import '../domain/response/Customer.dart';
import '../views/user/user_dashboard.dart';

class ZoomDrawerPage extends StatefulWidget {
  final Customer? customer;
  final bool isUser;
  final String? userName;
  final String? token;

  const ZoomDrawerPage({
    super.key,
    this.token,
    this.customer,
    required this.isUser,
    this.userName,
  });

  @override
  State<ZoomDrawerPage> createState() => _ZoomDrawerPageState();
}

class _ZoomDrawerPageState extends State<ZoomDrawerPage> {
  final GlobalKey<MainPageState> _mainPageKey = GlobalKey();

  void openPage(int index) {
    if (!widget.isUser) {
      _mainPageKey.currentState?.setPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ZoomDrawer(
      menuScreen: DrawerScreen(onSelectPage: openPage),
      mainScreen: widget.isUser
          ? UserDashboardPage(
              userName: widget.userName ?? '',
              token: widget.token!,
            )
          : MainPage(key: _mainPageKey, customer: widget.customer!),
      borderRadius: 28,
      showShadow: true,
      angle: 0.0,
      drawerShadowsBackgroundColor: const Color.fromARGB(255, 47, 142, 138),
      slideWidth: MediaQuery.of(context).size.width * 0.80,
      menuBackgroundColor: Colors.white,
    );
  }
}
