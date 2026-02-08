import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  
  // ✅ Variable pour stocker le token réel
  String _actualToken = '';

  @override
  void initState() {
    super.initState();
    // ✅ DEBUG et récupération du token
    print('=== DEBUG USER DASHBOARD INIT ===');
    print('Token reçu en paramètre: ${widget.token}');
    print('Token length: ${widget.token.length}');
    print('Token vide? ${widget.token.isEmpty}');
    
    _loadToken();
  }

  // ✅ Fonction pour charger le token depuis SharedPreferences si nécessaire
  Future<void> _loadToken() async {
    if (widget.token.isNotEmpty) {
      // Si le token est passé en paramètre, l'utiliser
      _actualToken = widget.token;
      print('Token utilisé depuis paramètre: $_actualToken');
    } else {
      // Sinon, essayer de le récupérer depuis SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _actualToken = prefs.getString('token') ?? '';
      print('Token récupéré depuis SharedPreferences: $_actualToken');
      
      if (_actualToken.isEmpty) {
        print('❌ ERREUR: Aucun token disponible!');
        // Vous pouvez rediriger vers la page de login ici
      }
    }
    
    // Charger les données une fois qu'on a le token
    fetchStockEntries();
  }

  void setPage(int index) {
    setState(() => _currentPageIndex = index);
  }

  void fetchStockEntries() async {
    print('=== FETCH STOCK ENTRIES ===');
    print('Token utilisé pour fetch: $_actualToken');
    
    final StockEntryResponse? response = await controller.fetchLastStockEntries(
      token: _actualToken,
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
                            // ✅ DEBUG avant navigation
                            print('=== NAVIGATION VERS STOCK ENTRY ===');
                            print('Token passé: $_actualToken');
                            print('Stock Entry Name: ${entry.name}');
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StockEntryPage(
                                  stockEntryName: entry.name,
                                  token: _actualToken, // ✅ Utiliser _actualToken au lieu de widget.token
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