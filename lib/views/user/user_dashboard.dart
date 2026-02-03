import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import '../../widgets/header.dart';
import '../../../application/controllers/StockEntryController.dart';
import '../../../domain/response/StockEntry.dart';
import '../../../domain/response/StockEntryResponse.dart';
import 'stock_entry.dart';

class UserDashboardPage extends StatefulWidget {
  final String userName;
  final String token;
  final ZoomDrawerController drawerController;

  const UserDashboardPage({
    super.key,
    required this.userName,
    required this.token,
    required this.drawerController,
  });

  @override
  State<UserDashboardPage> createState() => UserDashboardPageState();
}

class UserDashboardPageState extends State<UserDashboardPage> {
  final StockEntryController controller = StockEntryController();
  List<StockEntry> stockEntries = [];
  bool isLoading = true;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchStockEntries(); // Charge les données dès le début
  }

  void setPage(int index) {
    setState(() => _currentPageIndex = index);
  }

  void fetchStockEntries() async {
    final StockEntryResponse? response = await controller.fetchLastStockEntries(
      token: widget.token,
      limit: 10,
    );

    if (response != null) {
      setState(() {
        stockEntries = response.stockEntries;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Color statusColor(String status) {
    if (status.toLowerCase() == "approved") {
      return Colors.teal;
    }
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    Widget currentPage;
    switch (_currentPageIndex) {
      case 0:
        currentPage = _buildEmptyHome();
        break;
      case 1:
        currentPage = _buildNotifications();
        break;
      case 2:
        currentPage = _buildStockManagement();
        break;
      default:
        currentPage = _buildEmptyHome();
    }
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 255, 254),
      body: currentPage,
    );
  }

  // --- 1. ACCUEIL VIDE ---
  Widget _buildEmptyHome() {
    return Column(
      children: [
        AppHeader(
          title: 'Home',
          customer: null,
          customerCode: '',
          onMenuTap: () => widget.drawerController.toggle!(),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_pin, size: 100, color: Color(0xFF3BADA2)),
                const SizedBox(height: 20),
                Text(
                  "Welcome, ${widget.userName}",
                  style: const TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold, 
                    color: Color(0xFF1F2837),
                  ),
                ),
                const Text("Select a service from the menu to start", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 2. PAGE DE STOCK (AVEC LES TRANSFERTS) ---
  Widget _buildStockManagement() {
    return Column(
      children: [
        AppHeader(
          title: 'Stock ',
          customer: null,
          customerCode: '',
          onMenuTap: () => widget.drawerController.toggle!(),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Recent Stock Transfers",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...stockEntries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StockEntryPage(
                                  stockEntryName: entry.name,
                                  token: widget.token,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Stock Entry : ${entry.name}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color.fromRGBO(31, 40, 55, 1),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        entry.posting_date,
                                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  entry.status,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor(entry.status),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildNotifications() {
    return Column(
      children: [
        AppHeader(
          title: 'Notifications',
          customer: null,
          customerCode: '',
          onMenuTap: () => widget.drawerController.toggle!(),
        ),
        const Expanded(child: Center(child: Text("No new notifications"))),
      ],
    );
  }
}