import 'package:flutter/material.dart';
import '../../widgets/header.dart';
import '../../widgets/invoice_filter_bar.dart';
import '../../utils/invoice_utils.dart';
import '../../../application/controllers/invoice_controller.dart';
import '../../../domain/response/InvoicesResponse.dart';
import '../../domain/response/sales_invoice.dart';
import '../../../domain/response/Customer.dart';
import 'invoice_detail_page.dart';

class InvoicePage extends StatefulWidget {
  final String customerCode;
  final Customer customer;

  const InvoicePage({
    super.key,
    required this.customerCode,
    required this.customer,
  });

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  String searchQuery = '';
  String selectedStatus = 'All';

  final InvoiceController controller = InvoiceController();
  List<SalesInvoice> salesInvoices = [];
  List<SalesInvoice> posInvoices = [];
  
  // États pour le chargement et la pagination
  bool isLoading = true; // Chargement initial
  bool isLoadingMore = false; // Chargement du bouton "Voir plus"
  bool hasMore = true; // S'il reste des données à charger
  int _offset = 0;
  final int _limit = 20;

  int selectedTab = 0;

  late ScrollController scrollController;
  bool isHeaderVisible = true;
  double lastOffset = 0;

  @override
  void initState() {
    super.initState();

    scrollController = ScrollController();
    // On garde juste la logique pour masquer/afficher le header
    // On a ENLEVÉ la logique de pagination automatique ici
    scrollController.addListener(() {
      final currentOffset = scrollController.offset;
      if (currentOffset > lastOffset && currentOffset > 50) {
        if (isHeaderVisible) setState(() => isHeaderVisible = false);
      } else if (currentOffset < lastOffset) {
        if (!isHeaderVisible) setState(() => isHeaderVisible = true);
      }
      lastOffset = currentOffset;
    });

    fetchInvoices();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  // Action quand on tire vers le bas (Refresh)
  Future<void> _onRefresh() async {
    setState(() {
      isLoading = true;
      hasMore = true;
      _offset = 0; // On remet le compteur à 0
      salesInvoices.clear(); // On vide les listes
      posInvoices.clear();
    });
    await fetchInvoices(isLoadMore: false);
  }

  // Action quand on clique sur le bouton "Afficher 20 suivants"
  Future<void> _onLoadMore() async {
    if (!isLoadingMore && hasMore) {
      await fetchInvoices(isLoadMore: true);
    }
  }

  Future<void> fetchInvoices({bool isLoadMore = false}) async {
    if (isLoadMore) {
      setState(() => isLoadingMore = true);
    } else {
      // Si ce n'est pas un "load more", c'est un refresh ou un init
      if (!mounted) return;
      // On ne met isLoading à true que si on n'a pas de données (pour éviter l'écran blanc au refresh)
      if (salesInvoices.isEmpty && posInvoices.isEmpty) {
        setState(() => isLoading = true);
      }
    }

    try {
      final InvoicesResponse? response = await controller.fetchInvoices(
        widget.customerCode,
        limit: _limit,
        offset: _offset,
      );

      if (response != null && mounted) {
        setState(() {
          if (isLoadMore) {
            salesInvoices.addAll(response.sales_invoices);
            posInvoices.addAll(response.pos_invoices);
          } else {
            salesInvoices = response.sales_invoices;
            posInvoices = response.pos_invoices;
          }

          // Vérification si on est à la fin
          if (response.sales_invoices.length < _limit && response.pos_invoices.length < _limit) {
            hasMore = false;
          } else {
            _offset += _limit; // On prépare les 20 suivants
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de la récupération des factures")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
      }
    }
  }

  List<InvoiceItemData> get filteredSalesItems {
    return salesInvoices
        .where(
          (item) =>
              item.name.toLowerCase().contains(searchQuery.toLowerCase()) &&
              (selectedStatus == 'All' || item.status == selectedStatus),
        )
        .map(
          (item) => InvoiceItemData(
            title: item.name,
            ttc: item.outstanding_amount,
            price: item.grand_total,
            postingDate: item.posting_date,
            status: item.status,
          ),
        )
        .toList();
  }

  List<InvoiceItemData> get filteredPOSItems {
    return posInvoices
        .where(
          (item) =>
              item.name.toLowerCase().contains(searchQuery.toLowerCase()) &&
              (selectedStatus == 'All' || item.status == selectedStatus),
        )
        .map(
          (item) => InvoiceItemData(
            title: item.name,
            ttc: item.outstanding_amount,
            price: item.grand_total,
            postingDate: item.posting_date,
            status: item.status,
          ),
        )
        .toList();
  }

  // ... (buildTabs et buildTabContent restent identiques, je les inclus pour la complétude)
  Widget buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F7F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Sales Invoices",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: selectedTab == 0
                        ? const Color.fromARGB(255, 0, 167, 155)
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  "POS Invoices",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: selectedTab == 1
                        ? const Color.fromARGB(255, 0, 167, 155)
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTabContent() {
    final items = selectedTab == 0 ? filteredSalesItems : filteredPOSItems;
    final type = selectedTab == 0 ? "sales" : "pos";

    return InvoiceList(
      invoiceType: type,
      items: items,
      onInvoiceTap: (item) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceDetailPage(
              invoiceName: item.title,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 255, 253, 1),
      body: Column(
        children: [
          AppHeader(
            title: '',
            customer: widget.customer,
            customerCode: widget.customer.code,
          ),
          InvoiceFilterBar(
            selectedStatus: selectedStatus,
            onSearchChanged: (value) => setState(() => searchQuery = value),
            onStatusChanged: (value) {
              if (value != null) setState(() => selectedStatus = value);
            },
          ),
          const SizedBox(height: 12),

          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: isHeaderVisible ? null : 0,
            curve: Curves.easeInOut,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(245, 235, 234, 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Outstanding Amount",
                              style: TextStyle(
                                fontSize: 18,
                                color: Color.fromRGBO(238, 33, 33, 1),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.customer.debt.toStringAsFixed(2)} DA',
                              style: const TextStyle(
                                fontSize: 30,
                                color: Color.fromRGBO(31, 40, 55, 1),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 239, 69, 68),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.credit_card,
                            size: 30,
                            color: Color.fromRGBO(254, 255, 255, 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  buildTabs(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          Expanded(
            child: Container(
              color: const Color.fromARGB(255, 252, 253, 253),
              // PULL-TO-REFRESH : Permet de remettre à zéro et charger les 20 premiers
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: const Color.fromARGB(255, 0, 167, 155),
                child: isLoading && !isLoadingMore
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        controller: scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            buildTabContent(),

                            // --- BOUTON DE PAGINATION MANUELLE ---
                            if (hasMore && (salesInvoices.isNotEmpty || posInvoices.isNotEmpty))
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                                child: isLoadingMore
                                    ? const Center(child: CircularProgressIndicator())
                                    : SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _onLoadMore,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: const Color.fromARGB(255, 0, 167, 155),
                                            elevation: 0,
                                            side: const BorderSide(color: Color.fromARGB(255, 0, 167, 155)),
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
                                      ),
                              ),

                            // Si tout est chargé
                            if (!hasMore && (salesInvoices.isNotEmpty || posInvoices.isNotEmpty))
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text("All invoices loaded", 
                                  style: TextStyle(color: Colors.grey)),
                              ),

                            // Cas vide
                            if (salesInvoices.isEmpty && posInvoices.isEmpty && !isLoading)
                              const Padding(
                                padding: EdgeInsets.only(top: 50),
                                child: Center(child: Text("Aucune facture trouvée")),
                              ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
              ),
            )
          ),
        ],
      ),
    );
  }
}