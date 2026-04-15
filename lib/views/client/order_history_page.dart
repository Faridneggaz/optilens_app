import 'package:flutter/material.dart';
import '../../application/controllers/order_controller.dart';
import 'order_page.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final _api = OrderController();
  List _orders = [];
  bool _loading = true;

  final Color primaryTeal = const Color(0xFF008075);
  final Color bgColor = const Color(0xFFF7FFFD);

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  _refresh() async {
    setState(() => _loading = true);
    final data = await _api.fetchOrders();
    setState(() {
      _orders = data;
      _loading = false;
    });
  }

  // --- 1. LOGIQUE DES COULEURS DE STATUT ---
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft': return Colors.blueGrey;
      case 'to deliver':
      case 'submitted': return Colors.blue;
      case 'completed':
      case 'closed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'on hold': return Colors.orange;
      default: return primaryTeal;
    }
  }

  // --- 2. FENÊTRE DE DÉTAILS COULISSANTE (DRAGGABLE) ---
  void _showOrderDetails(dynamic order) {
    String orderId = order['name'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permet de monter jusqu'en haut
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6, // Ouvre à 60%
        minChildSize: 0.4,     // Minimum 40%
        maxChildSize: 0.95,    // Maximum "Complet" (95%)
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              // Barre de drag
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 50, height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),

              // En-tête avec Date et Total
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                child: Column(
                  children: [
                    Text("COMMANDE $orderId", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: primaryTeal.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("DATE", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                              Text(order['transaction_date'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text("TOTAL", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                              Text("${order['grand_total']} DZD", 
                                style: TextStyle(color: primaryTeal, fontWeight: FontWeight.w900, fontSize: 16)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Liste des articles (Scrollable)
              Expanded(
                child: FutureBuilder(
                  future: _api.getOrderItems(orderId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: primaryTeal));
                    }
                    if (!snapshot.hasData || snapshot.data == null) {
                      return const Center(child: Text("Erreur de chargement"));
                    }
                    List items = snapshot.data as List;
                    return ListView.builder(
                      controller: scrollController, // Synchronise le drag et le scroll
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: items.length,
                      itemBuilder: (context, i) => _buildItemTile(items[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: primaryTeal))
                : RefreshIndicator(
                    onRefresh: () => _refresh(),
                    child: _orders.isEmpty 
                      ? const Center(child: Text("Aucune commande")) 
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 15, 20, 100),
                          itemCount: _orders.length,
                          itemBuilder: (context, i) => _buildOrderCard(_orders[i]),
                        ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // --- COMPOSANTS UI ---

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 10, right: 20),
      decoration: BoxDecoration(
        color: primaryTeal,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25)),
      ),
      child: Row(
        children: [
          const BackButton(color: Colors.white),
          const Expanded(
            child: Text("MES COMMANDES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Text("${_orders.length} TOTAL", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    String status = order['status'] ?? "Draft";
    Color statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order['transaction_date'] ?? "", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  Text("${order['grand_total']} DZD", style: TextStyle(color: primaryTeal, fontWeight: FontWeight.w900, fontSize: 17)),
                ],
              ),
              TextButton(
                onPressed: () => _showOrderDetails(order),
                style: TextButton.styleFrom(
                  backgroundColor: primaryTeal.withOpacity(0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text("Détails >", style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildItemTile(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['item_code'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text("Qté: ${item['qty']} x ${item['rate']} DZD", style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Text("${item['amount']} DZD", style: TextStyle(fontWeight: FontWeight.bold, color: primaryTeal)),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderPage())).then((_) => _refresh()),
      backgroundColor: primaryTeal,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text("NOUVELLE COMMANDE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    );
  }
}