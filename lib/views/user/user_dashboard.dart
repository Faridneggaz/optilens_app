import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/header.dart';
import '../../../application/controllers/StockEntryController.dart';
import '../../../domain/response/StockEntry.dart';
import '../../../domain/response/StockEntryResponse.dart';
import 'stock_entry.dart';
import '../../utils/responsive_utils.dart';

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
  
  // États de chargement et pagination
  bool isLoading = true;         // Chargement initial ou Refresh complet
  bool isLoadingMore = false;    // Chargement du bouton "Voir plus"
  bool hasMore = true;           // Reste-t-il des données ?
  int _offset = 0;
  final int _limit = 20;
  
  int _currentPageIndex = 0;
  String _actualToken = '';

  // --- NOUVEAUX ÉTATS POUR LA RECHERCHE ET LE FILTRE ---
  String _searchQuery = '';
  String _selectedStatus = 'All';

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

  Future<void> _onRefresh() async {
    setState(() {
      isLoading = true;
      hasMore = true;
      _offset = 0;
      stockEntries.clear(); 
      // Réinitialiser les filtres au rafraîchissement si vous le souhaitez
      // _searchQuery = '';
      // _selectedStatus = 'All';
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
              _offset += _limit;
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
    if (status.toLowerCase() == "pending") return Colors.orange;
    if (status.toLowerCase() == "draft") return Colors.grey;
    return Colors.black;
  }

  // --- LOGIQUE DE FILTRAGE ---
  List<StockEntry> get _filteredEntries {
    return stockEntries.where((entry) {
      final matchesSearch = entry.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatus == 'All' || entry.status.toLowerCase() == _selectedStatus.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();
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
        AppHeader(title: 'Stock', customer: null, customerCode: '', onMenuTap: () => widget.drawerController.toggle!()),
        
        // --- INTÉGRATION DE LA BARRE DE FILTRE CENTRÉE ---
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000), // Empêche l'étirement sur PC/Tablette
            child: StockFilterBar(
              selectedStatus: _selectedStatus,
              onSearchChanged: (val) => setState(() => _searchQuery = val),
              onStatusChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),
          ),
        ),
        
        Expanded(
          // --- CENTRAGE DE LA LISTE / GRILLE ---
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000), // Même contrainte que la barre
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: Colors.teal,
                child: isLoading && !isLoadingMore
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredEntries.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 100),
                              Center(child: Text("No stock entries found")),
                            ],
                          )
                        // Utilisation du ResponsiveLayout pour choisir entre Liste et Grille
                        : ResponsiveLayout.isMobile(context) 
                            ? _buildStockList()
                            : _buildStockGrid(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- AFFICHAGE TÉLÉPHONE (LISTE) ---
  Widget _buildStockList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 20),
      itemCount: _filteredEntries.length + 1,
      itemBuilder: (context, index) {
        if (index < _filteredEntries.length) {
          return _buildStockItem(_filteredEntries[index]);
        } else {
          return _buildLoadMoreButton();
        }
      },
    );
  }

  // --- AFFICHAGE TABLETTE (GRILLE 2 COLONNES) ---
  Widget _buildStockGrid() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            children: List.generate(_filteredEntries.length, (index) {
              return SizedBox(
                // On s'assure de prendre un peu moins de la moitié pour gérer les marges
                width: ResponsiveLayout.isDesktop(context) ? 450 : 350, 
                child: _buildStockItem(_filteredEntries[index]),
              );
            }),
          ),
          const SizedBox(height: 20),
          _buildLoadMoreButton(),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    // Si une recherche est en cours, cacher le bouton "Load More" est une bonne pratique
    if (_searchQuery.isNotEmpty || _selectedStatus != 'All') {
      return const SizedBox.shrink();
    }

    if (!hasMore && stockEntries.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text("All entries loaded", style: TextStyle(color: Colors.grey))),
      );
    }
    
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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

// =========================================================================
// WIDGET ADAPTÉ DE VOTRE INVOICE FILTER BAR (spécial Stock Entry)
// =========================================================================

class StockFilterBar extends StatefulWidget {
  final void Function(String) onSearchChanged;
  final void Function(String?) onStatusChanged;
  final String selectedStatus;

  const StockFilterBar({
    super.key,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.selectedStatus,
  });

  @override
  State<StockFilterBar> createState() => _StockFilterBarState();
}

class _StockFilterBarState extends State<StockFilterBar> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 247, 255, 254), // Raccord avec le fond
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade100, width: 1),
              ),
              child: TextField(
                controller: _controller,
                onChanged: widget.onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search MAT-STE...',
                  prefixIcon: Icon(Icons.search, color: Colors.teal),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Menu déroulant pour le statut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade100, width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                icon: const Icon(Icons.filter_list, color: Colors.teal),
                value: widget.selectedStatus,
                items: ['All', 'Approved', 'Pending', 'Draft']
                    .map(
                      (status) =>
                          DropdownMenuItem(value: status, child: Text(status)),
                    )
                    .toList(),
                onChanged: widget.onStatusChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}