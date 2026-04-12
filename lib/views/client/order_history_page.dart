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

  final Color primaryTeal = const Color(0xFF008075); // Ton vert Optilens
  final Color bgColor = const Color(0xFFF7FFFD);

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  _refresh() async {
    final data = await _api.fetchOrders();
    setState(() {
      _orders = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: primaryTeal),
        title: Text("My Orders", style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: Icon(Icons.search, color: primaryTeal), onPressed: () {}),
          IconButton(icon: Icon(Icons.filter_list, color: primaryTeal), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSectionHeader(),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: primaryTeal))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _orders.length,
                    itemBuilder: (context, i) => _buildOrderCard(_orders[i]),
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildFAB(),
    );
  }

  // 1. Barre de recherche stylée
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Rechercher une commande...",
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: primaryTeal, borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.tune, color: Colors.white),
          )
        ],
      ),
    );
  }

  // 2. Titre de section "Commandes récentes"
  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("COMMANDES RÉCENTES", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 12)),
          Text("${_orders.length} commandes au total", style: TextStyle(color: primaryTeal, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // 3. LA CARTE DE COMMANDE (Le cœur du design)
  Widget _buildOrderCard(dynamic order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  Text(order['transaction_date'], style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                ],
              ),
              _buildStatusBadge(order['status']),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                  image: const DecorationImage(image: NetworkImage("https://via.placeholder.com/150"), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Commande Optilens", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text("Verres & Montures", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("TOTAL", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text("${order['grand_total']} DZD", style: TextStyle(color: primaryTeal, fontWeight: FontWeight.w900, fontSize: 18)),
                ],
              ),
              ElevatedButton(
                onPressed: () => _showDetails(order['name']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal.withOpacity(0.1),
                  foregroundColor: primaryTeal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Détails >", style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFB2EBF2).withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(status.toUpperCase(), style: const TextStyle(color: Color(0xFF00838F), fontSize: 10, fontWeight: FontWeight.bold)),
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

  void _showDetails(String id) { /* Ta fonction bottom sheet ici */ }
}