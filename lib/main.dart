import 'package:flutter/material.dart';
import 'widgets/bottom_navbar.dart';
import 'views/client/Dashboard_view.dart';
import 'views/client/Invoice_view.dart';
import 'views/client/Payment_view.dart';
import 'views/client/Profil_view.dart';
import 'views/client/login_view.dart';
import 'domain/response/Customer.dart';
import 'widgets/logout_dialogue.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainPage extends StatefulWidget {
  final Customer customer;
  final int selectedIndex;

  const MainPage({super.key, required this.customer, this.selectedIndex = 0});

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  late int _selectedIndex;
  late final List<Widget> _pages;
  final List<int> _navigationHistory = [];

  void setPage(int index) {
    if (index < 0 || index >= _pages.length) return;

    setState(() {
      _selectedIndex = index;
      _navigationHistory.add(index);
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _navigationHistory.add(_selectedIndex);

    _pages = [
      DashboardPage(customer: widget.customer),
      InvoicePage(
        customerCode: widget.customer.code,
        customer: widget.customer,
      ),
      PaymentPage(
        customer: widget.customer,
        customerCode: widget.customer.code,
      ),
      ProfilePage(
        customer: widget.customer,
        customerCode: widget.customer.code,
        logout: () => LogoutDialog.show(context),
      ),
    ];
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
      _navigationHistory.add(index);
    });
  }

  Future<bool> _onWillPop() async {
    if (_navigationHistory.length > 1) {
      setState(() {
        _navigationHistory.removeLast();
        _selectedIndex = _navigationHistory.last;
      });
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
