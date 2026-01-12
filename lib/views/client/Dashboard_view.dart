import 'package:flutter/material.dart';
import '../../widgets/header.dart';
import '../../utils/announcement_utils.dart';
import '../../../application/controllers/invoice_controller.dart';
import '../../../domain/response/InvoicesResponse.dart';
import '../../domain/response/sales_invoice.dart';
import '../../../domain/response/Customer.dart';
import '../../utils/card_utils.dart';

class DashboardPage extends StatefulWidget {
  final Customer customer;

  const DashboardPage({super.key, required this.customer});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final InvoiceController controller = InvoiceController();
  List<SalesInvoice> invoices = [];
  bool isLoading = true;
  double totalOutstanding = 0;

  @override
  void initState() {
    super.initState();
    fetchInvoices();
  }

  void fetchInvoices() async {
    setState(() => isLoading = true);

    final InvoicesResponse? response = await controller.fetchInvoices(
      widget.customer.code,
    );

    setState(() {
      if (response != null) {
        invoices = response.sales_invoices;
        totalOutstanding = invoices.fold(
          0,
          (sum, item) => sum + item.outstanding_amount,
        );
      }
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: const Color.fromARGB(255, 246, 255, 253),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 20),
                children: [
                  AppHeader(
                    title: 'Dashboard',
                    customer: widget.customer,
                    customerCode: widget.customer.code,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(221, 244, 242, 11),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color.fromRGBO(0, 168, 156, 1),
                        width: 4,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
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
                          style: TextStyle(
                            fontSize: 32,
                            color: Color.fromRGBO(31, 40, 55, 1),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
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

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Announcements",
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

                  const AnnouncementCard(
                    icon: Icons.campaign,
                    title: "New Product Launch",
                    subtitle:
                        "We're excited to announce our latest collection of premium lenses, available starting next month!",
                    postedTime: "Posted 2 hours ago",
                    isNew: true,
                  ),

                  const AnnouncementCard(
                    icon: Icons.calendar_month,
                    title: "Holiday Hours Update",
                    subtitle:
                        "Please note that we will be closed for the upcoming public holiday on May 1st.",
                    postedTime: "Posted 3 days ago",
                    isNew: false,
                  ),

                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      "View All",
                      style: TextStyle(
                        color: Colors.teal.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
