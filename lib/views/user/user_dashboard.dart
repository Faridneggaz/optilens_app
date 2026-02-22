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
  
  // États de chargement et pagination (Comme Invoice)
  bool isLoading = true;         // Chargement initial ou Refresh complet
  bool isLoadingMore = false;    // Chargement du bouton "Voir plus"
  bool hasMore = true;           // Reste-t-il des données ?
  int _offset = 0;
  final int _limit = 20;
  
  int _currentPageIndex = 0;
  String _actualToken = '';

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    if (widget.token.isNotEmpty) {
      _actualToken = widget.token;
    } else {
      final prefs = await SharedPreferences.getInstance();
      _actualToken = prefs.getString('token') ?? '';
    }
    fetchStockEntries(); // Chargement initial
  }

  // Action Refresh (Tirer vers le bas)
  Future<void> _onRefresh() async {
    setState(() {
      isLoading = true;
      hasMore = true;
      _offset = 0;
      stockEntries.clear(); // On vide la liste pour recharger propre
    });
    await fetchStockEntries(isLoadMore: false);
  }

  // Action Bouton "Afficher plus"
  Future<void> _onLoadMore() async {
    if (!isLoadingMore && hasMore) {
      await fetchStockEntries(isLoadMore: true);
    }
  }

  Future<void> fetchStockEntries({bool isLoadMore = false}) async {
    if (isLoadMore) {
      setState(() => isLoadingMore = true);
    } else {
      if (!mounted) return;
      if (stockEntries.isEmpty) {
        setState(() => isLoading = true);
      }
    }

    try {
      final response = await controller.fetchLastStockEntries(
        token: _actualToken,
        limit: _limit,
        offset: _offset,
      );

      if (mounted) {
        setState(() {
          if (response != null) {
            if (isLoadMore) {
              stockEntries.addAll(response.stockEntries);
            } else {
              stockEntries = response.stockEntries;
            }

            // Vérification fin de liste
            if (response.stockEntries.length < _limit) {
              hasMore = false;
            } else {
              _offset += _limit; // On prépare l'offset pour la prochaine page
            }
          }
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur de connexion")),
        );
      }
    }
  }

  void setPage(int index) {
    setState(() => _currentPageIndex = index);
  }

  Color statusColor(String status) {
    if (status.toLowerCase() == "approved") return Colors.teal;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    Widget currentPage;
    switch (_currentPageIndex) {
      case 0: currentPage = _buildEmptyHome(); break;
      case 1: currentPage = _buildNotifications(); break;
      case 2: currentPage = _buildStockManagement(); break;
      default: currentPage = _buildEmptyHome();
    }
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 255, 254),
      body: currentPage,
    );
  }

  Widget _buildEmptyHome() {
    return Column(
      children: [
        AppHeader(title: 'Home', customer: null, customerCode: '', onMenuTap: () => widget.drawerController.toggle!()),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_pin, size: 100, color: Color(0xFF3BADA2)),
                const SizedBox(height: 20),
                Text("Welcome, ${widget.userName}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2837))),
                const Text("Select a service from the menu to start", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStockManagement() {
    return Column(
      children: [
        AppHeader(title: 'Stock ', customer: null, customerCode: '', onMenuTap: () => widget.drawerController.toggle!()),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: Colors.teal,
            child: isLoading && !isLoadingMore
                ? const Center(child: CircularProgressIndicator())
                : stockEntries.isEmpty
                    ? ListView( // ListView permet le refresh même vide
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 100),
                          Center(child: Text("No stock entries found")),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        // +1 pour le bouton en bas
                        itemCount: stockEntries.length + 1,
                        itemBuilder: (context, index) {
                          if (index < stockEntries.length) {
                            return _buildStockItem(stockEntries[index]);
                          } else {
                            // Zone du bouton en bas
                            return _buildLoadMoreButton();
                          }
                        },
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadMoreButton() {
    // Si tout est chargé
    if (!hasMore && stockEntries.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text("All entries loaded", style: TextStyle(color: Colors.grey))),
      );
    }
    
    // Si on est en train de charger la suite
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Bouton pour charger la suite
    if (hasMore && stockEntries.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ElevatedButton(
          onPressed: _onLoadMore,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.teal,
            elevation: 0,
            side: const BorderSide(color: Colors.teal),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            "Load More (20)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStockItem(StockEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StockEntryPage(
                stockEntryName: entry.name,
                token: _actualToken,
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color.fromRGBO(31, 40, 55, 1)),
                    ),
                    const SizedBox(height: 4),
                    Text(entry.posting_date, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              Text(
                entry.status,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: statusColor(entry.status)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotifications() {
    return Column(
      children: [
        AppHeader(title: 'Notifications', customer: null, customerCode: '', onMenuTap: () => widget.drawerController.toggle!()),
        const Expanded(child: Center(child: Text("No new notifications"))),
      ],
    );
  }
}