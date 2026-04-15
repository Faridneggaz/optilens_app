import 'package:flutter/material.dart';
import '../../widgets/header.dart';
import '../../utils/announcement_utils.dart';
import '../../../application/controllers/invoice_controller.dart';
import '../../../domain/response/InvoicesResponse.dart';
import '../../domain/response/sales_invoice.dart';
import '../../../domain/response/Customer.dart';
import '../../utils/card_utils.dart';

import '../../../application/controllers/announcement_controller.dart';
import '../../../domain/response/announcement.dart';

class DashboardPage extends StatefulWidget {
  final Customer customer;

  const DashboardPage({super.key, required this.customer});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Controllers
  final InvoiceController invoiceController = InvoiceController();
  final AnnouncementController announcementController = AnnouncementController();

  // Data Lists
  List<SalesInvoice> invoices = [];
  List<Announcement> announcements = [];

  // Loading States
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
    final InvoicesResponse? response = await invoiceController.fetchInvoices(
      widget.customer.code,
    );
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

    final String userId = widget.customer.code; 
    
    final result = await announcementController.fetchAnnouncements(userId);
    
    if (mounted) {
      setState(() {
        announcements = result;
        isAnnouncementsLoading = false;
      });
    }
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'local_offer': return Icons.local_offer;
      case 'warning': return Icons.warning_amber_rounded;
      case 'event': return Icons.event;
      case 'info': return Icons.info_outline;
      case 'campaign': return Icons.campaign;
      default: return Icons.notifications;
    }
  }

  Color _parseColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = "FF$hexColor"; 
      }
      return Color(int.parse("0x$hexColor"));
    } catch (e) {
      return const Color.fromRGBO(0, 169, 157, 1); 
    }
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
                  // HEADER
                  AppHeader(
                    title: '',
                    customer: widget.customer,
                    customerCode: widget.customer.code,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // OUTSTANDING CARD
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                    
                      color: const Color.fromRGBO(221, 244, 242, 1.0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color.fromRGBO(0, 168, 156, 1),
                        width: 4,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "OutStanding Amount",
                          style: TextStyle(
                            fontSize: 20,
                            color: Color.fromRGBO(1, 169, 156, 1),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${widget.customer.debt.toStringAsFixed(2)} DA',
                          style: const TextStyle(
                            fontSize: 32,
                            color: Color.fromRGBO(31, 40, 55, 1),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                  
                  // DASHBOARD SECTION
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Dashboard",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color.fromRGBO(31, 40, 55, 1),
                          ),
                        ),
                        SizedBox(height: 12),
                      ],
                    ),
                  ),

                  buildSimpleCard("Price List", "PL-Standard"),
                  const SizedBox(height: 16),
                  buildSimpleCard("TTC/Month", "350.00 DA"),
                  const SizedBox(height: 20),

                  // ANNOUNCEMENTS SECTION (DYNAMIQUE)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Announcements",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color.fromRGBO(31, 40, 55, 1),
                          ),
                        ),
                        if (isAnnouncementsLoading)
                          const SizedBox(
                            height: 20, 
                            width: 20, 
                            child: CircularProgressIndicator(strokeWidth: 2)
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // LISTE DYNAMIQUE DES ANNONCES
                  if (!isAnnouncementsLoading && announcements.isEmpty)
                     Padding(
                       padding: const EdgeInsets.all(20.0),
                       child: Center(child: Text("No new announcements", style: TextStyle(color: Colors.grey.shade500))),
                     )
                  else
                    ...announcements.map((ann) => AnnouncementCard(
                      icon: _getIcon(ann.icon),
                      title: ann.title,
                      subtitle: ann.subtitle,
                      postedTime: "Posted ${ann.postedTime}",
                      // On compare la date du jour avec la date de l'annonce pour le tag "NEW"
                      isNew: ann.postedTime == DateTime.now().toString().split(' ')[0], 
                      themeColor: _parseColor(ann.color),
                    )),

                  const SizedBox(height: 12),
                  
                  Center(
                    child: TextButton(
                      onPressed: () {
                         
                      },
                      child: Text(
                        "View All",
                        style: TextStyle(
                          color: Colors.teal.shade600,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}