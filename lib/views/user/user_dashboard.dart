import 'package:flutter/material.dart';
import '../../widgets/header.dart';
import '../../../application/controllers/StockEntryController.dart';
import '../../../domain/response/StockEntry.dart';
import '../../../domain/response/StockEntryResponse.dart';
import 'stock_entry.dart';

class UserDashboardPage extends StatefulWidget {
  final String userName;
  final String token;

  const UserDashboardPage({
    super.key,
    required this.userName,
    required this.token,
  });

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  final StockEntryController controller = StockEntryController();
  List<StockEntry> stockEntries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStockEntries();
  }

  void fetchStockEntries() async {
    final StockEntryResponse? response = await controller.fetchLastStockEntries(
      token: widget.token,
      limit: 10,
    );

    if (response != null) {
      setState(() {
        stockEntries = response.stockEntries;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Color statusColor(String status) {
    if (status.toLowerCase() == "approved") {
      return Colors.teal;
    }
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 255, 254),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          AppHeader(title: 'Dashboard', customer: null, customerCode: ''),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(221, 244, 242, 1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color.fromRGBO(0, 168, 156, 1),
                width: 4,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Hello",
                  style: TextStyle(
                    fontSize: 20,
                    color: Color.fromRGBO(1, 169, 156, 1),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.userName,
                  style: const TextStyle(
                    fontSize: 28,
                    color: Color.fromRGBO(31, 40, 55, 1),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Recent Stock Transfers",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color.fromRGBO(31, 40, 55, 1),
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ...stockEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StockEntryPage(
                          stockEntryName: entry.name,
                          token: widget.token,
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
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color.fromRGBO(31, 40, 55, 1),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.posting_date,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          entry.status,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: statusColor(entry.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
