import 'package:flutter/material.dart';
import '../../application/controllers/invoice_detail_controller.dart';
import '../../domain/response/invoice_detail_response.dart';

class InvoiceDetailPage extends StatefulWidget {
  final String invoiceName;
  final String invoiceType;

  const InvoiceDetailPage({
    super.key,
    required this.invoiceName,
    this.invoiceType = "Sales Invoice",
  });

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  final InvoiceDetailController _controller = InvoiceDetailController();
  InvoiceDetailResponse? _invoiceData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvoiceDetails();
  }

  Future<void> _loadInvoiceDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Appel au contrôleur pour récupérer les données
      final data = await _controller.getInvoiceDetails(
        invoiceName: widget.invoiceName,
      );

      setState(() {
        if (data != null) {
          _invoiceData = data;
        } else {
          _error = 'Impossible de charger les détails de la facture';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur réseau ou serveur : $e';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('paid')) return Colors.green;
    if (s.contains('unpaid')) return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Invoice",
          style: TextStyle(color: Color(0xFF00A69C), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A69C)))
          : _error != null
              ? _buildErrorWidget()
              : _buildInvoiceContent(),
    );
  }

  Widget _buildInvoiceContent() {
    final inv = _invoiceData!.invoice;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre et Date
          Text(
            "Invoice #${inv.name}",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            "Issued: ${inv.postingDate}",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
          
          const SizedBox(height: 25),

          // Section BILLED TO : Affiche le Nom du Client (customerName)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Billed To:",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  inv.customer ?? "Client non spécifié",
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          const Text(
            "Items",
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Liste des articles stylisée
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _invoiceData!.items.length,
            itemBuilder: (context, index) {
              final item = _invoiceData!.items[index];
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.itemName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Qty: ${item.qty.toInt()}   Unit Price: ${item.rate.toStringAsFixed(2)} DA",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "${item.amount.toStringAsFixed(2)} DA",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 35),

          // TOTAL AMOUNT UNIQUEMENT
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                "Total Amount: ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              Text(
                "${inv.grandTotal.toStringAsFixed(2)} DA",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Statut de la facture centré
          Center(
            child: Text(
              "Status: ${inv.status}",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(inv.status),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.red),
          const SizedBox(height: 10),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadInvoiceDetails,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A69C)),
            child: const Text("Réessayer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}