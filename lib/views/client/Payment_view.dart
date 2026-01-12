import 'package:flutter/material.dart';
import '../../widgets/header.dart';
import '../../utils/payment_utils.dart';
import '../../../domain/response/Customer.dart';
import '../../../application/controllers/Paymentcontroller.dart';
import '../../domain/response/PaymentResponse.dart';

class PaymentPage extends StatefulWidget {
  final Customer customer;
  final String customerCode;

  const PaymentPage({
    super.key,
    required this.customer,
    required this.customerCode,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool isLoading = true;
  List<PaymentItemData> payments = [];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final PaymentResponse? response = await PaymentController().fetchPayments(
      widget.customerCode,
    );

    if (response != null) {
      setState(() {
        payments = response.payments.map((payment) {
          return PaymentItemData(
            paymentId: payment.name,
            date: payment.posting_date,
            invoices: payment.invoices_payed.map((inv) {
              return PaidInvoice(
                invoiceId: inv.invoice,
                amount: inv.allocated_amount,
              );
            }).toList(),
          );
        }).toList();

        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 255, 253, 1),
      body: Column(
        children: [
          AppHeader(
            title: 'Payments',
            customer: widget.customer,
            customerCode: widget.customerCode,
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () {
                print("Make a new payment tapped");
              },
              child: Card(
                color: const Color.fromARGB(255, 197, 236, 233),
                elevation: 2,
                shadowColor: Colors.black.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const SizedBox(
                  height: 60,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.credit_card,
                          size: 28,
                          color: Color.fromRGBO(0, 166, 154, 1),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Make a New Payment",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(0, 166, 154, 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : payments.isEmpty
                ? const Center(child: Text("No payments found"))
                : SingleChildScrollView(
                    child: PaymentList(
                      globalTitle: 'Payments History',
                      items: payments,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
