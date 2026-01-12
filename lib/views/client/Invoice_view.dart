import 'package:flutter/material.dart';
import '../../widgets/header.dart';
import '../../widgets/invoice_filter_bar.dart';
import '../../utils/invoice_utils.dart';
import '../../../application/controllers/invoice_controller.dart';
import '../../../domain/response/InvoicesResponse.dart';
import '../../domain/response/sales_invoice.dart';
import '../../../domain/response/Customer.dart';

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
  bool isLoading = true;

  int selectedTab = 0;

  late ScrollController scrollController;
  bool isHeaderVisible = true;
  double lastOffset = 0;

  @override
  void initState() {
    super.initState();

    scrollController = ScrollController();
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

  void fetchInvoices() async {
    setState(() => isLoading = true);

    try {
      final InvoicesResponse? response = await controller.fetchInvoices(
        widget.customerCode,
      );

      if (response != null) {
        salesInvoices = response.sales_invoices;
        posInvoices = response.pos_invoices;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de la récupération des factures"),
        ),
      );
    } finally {
      setState(() => isLoading = false);
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
                        ? Color.fromARGB(255, 0, 167, 155)
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
                        ? Color.fromARGB(255, 0, 167, 155)
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
    if (selectedTab == 0) {
      return InvoiceList(invoiceType: "sales", items: filteredSalesItems);
    }
    return InvoiceList(invoiceType: "pos", items: filteredPOSItems);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 255, 253, 1),
      body: Column(
        children: [
          AppHeader(
            title: 'Invoices',
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
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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
                          color: Color.fromARGB(255, 239, 69, 68),
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

          Expanded(
            child: Container(
              color: const Color.fromARGB(255, 252, 253, 253),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (salesInvoices.isEmpty && posInvoices.isEmpty)
                  ? const Center(child: Text('No invoices found'))
                  : SingleChildScrollView(
                      controller: scrollController,
                      child: buildTabContent(),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
