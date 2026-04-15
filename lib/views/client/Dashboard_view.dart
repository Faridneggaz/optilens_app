import 'package:flutter/material.dart';
import '../../widgets/header.dart';
import '../../utils/announcement_utils.dart';
import '../../../application/controllers/invoice_controller.dart';
import '../../../domain/response/InvoicesResponse.dart';
import '../../domain/response/sales_invoice.dart';
import '../../../domain/response/Customer.dart';
import '../../../application/controllers/announcement_controller.dart';
import '../../../domain/response/announcement.dart';
import 'announcement_detail_view.dart'; 

class DashboardPage extends StatefulWidget {
  final Customer customer;

  const DashboardPage({super.key, required this.customer});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final InvoiceController invoiceController = InvoiceController();
  final AnnouncementController announcementController = AnnouncementController();

  List<SalesInvoice> invoices = [];
  List<Announcement> announcements = [];

  bool isInvoiceLoading = true;
  bool isAnnouncementsLoading = true;
  double totalOutstanding = 0;

  @override
  void initState() {
    super.initState();
    fetchInvoices();
    fetchAnnouncements();
  }

  void fetchInvoices() async {
    setState(() => isInvoiceLoading = true);
    final InvoicesResponse? response = await invoiceController.fetchInvoices(widget.customer.code);
    if (mounted) {
      setState(() {
        if (response != null) {
          invoices = response.sales_invoices;
          totalOutstanding = invoices.fold(0, (sum, item) => sum + item.outstanding_amount);
        }
        isInvoiceLoading = false;
      });
    }
  }

  void fetchAnnouncements() async {
    setState(() => isAnnouncementsLoading = true);
    final result = await announcementController.fetchAnnouncements(widget.customer.code);
    if (mounted) {
      setState(() {
        announcements = result;
        isAnnouncementsLoading = false;
      });
    }
  }

  // --- Helper pour les petites cartes Dashboard ---
  Widget buildSimpleCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isInvoiceLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: const Color.fromARGB(255, 246, 255, 253),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 20),
                children: [
                  AppHeader(
                    title: '',
                    customer: widget.customer,
                    customerCode: widget.customer.code,
                  ),
                  const SizedBox(height: 20),
                  
                  // CARTE OUTSTANDING
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(221, 244, 242, 1.0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color.fromRGBO(0, 168, 156, 1), width: 4),
                    ),
                    child: Column(
                      children: [
                        const Text("OutStanding Amount",
                            style: TextStyle(fontSize: 20, color: Color.fromRGBO(1, 169, 156, 1), fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        Text('${widget.customer.debt.toStringAsFixed(2)} DA',
                            style: const TextStyle(fontSize: 32, color: Color.fromRGBO(31, 40, 55, 1), fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("Dashboard", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 12),

                  buildSimpleCard("Price List", "PL-Standard"),
                  const SizedBox(height: 16),
                  buildSimpleCard("TTC/Month", "350.00 DA"),
                  
                  const SizedBox(height: 25),

                  // SECTION ANNOUNCEMENTS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Announcements", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        if (isAnnouncementsLoading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 10),

                  if (!isAnnouncementsLoading && announcements.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No new announcements")))
                  else
                    ...announcements.map((ann) => AnnouncementCard(
                          announcement: ann,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AnnouncementDetailPage(announcement: ann)),
                            );
                          },
                        )),

                  const SizedBox(height: 12),
                  
                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        "View All",
                        style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}