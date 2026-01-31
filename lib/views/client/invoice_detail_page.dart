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
      final data = await _controller.fetchInvoiceDetails(
        invoiceName: widget.invoiceName,
        invoiceType: widget.invoiceType,
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
        _error = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('paid') && !statusLower.contains('unpaid')) {
      return Colors.green;
    } else if (statusLower.contains('unpaid')) {
      return Colors.red;
    } else if (statusLower.contains('partly') || statusLower.contains('overdue')) {
      return Colors.orange;
    }
    return Colors.grey;
  }

  String _formatCurrency(double amount) {
    return "${amount.toStringAsFixed(2)} DA";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 255, 253, 1),
      appBar: AppBar(
        title: const Text(
          "Invoice Details",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(31, 40, 55, 1),
          ),
        ),
        backgroundColor: const Color.fromRGBO(247, 255, 253, 1),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color.fromRGBO(31, 40, 55, 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromRGBO(31, 40, 55, 1),
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadInvoiceDetails,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(31, 40, 55, 1),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _invoiceData == null
                  ? const Center(child: Text('Aucune donnée disponible'))
                  : RefreshIndicator(
                      onRefresh: _loadInvoiceDetails,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),

                            /// 🧾 INVOICE HEADER CARD
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.receipt_long,
                                        color: Color.fromRGBO(31, 40, 55, 1),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _invoiceData!.invoice.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                                  _invoiceData!.invoice.status)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: _getStatusColor(
                                                _invoiceData!.invoice.status),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(
                                                    _invoiceData!.invoice.status),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _invoiceData!.invoice.status,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: _getStatusColor(
                                                    _invoiceData!.invoice.status),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _invoiceData!.invoice.postingDate,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            /// 💰 TOTALS CARDS
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoCard(
                                      title: "Grand Total",
                                      value: _formatCurrency(
                                          _invoiceData!.invoice.grandTotal),
                                      icon: Icons.attach_money,
                                      valueColor: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildInfoCard(
                                      title: "Outstanding",
                                      value: _formatCurrency(_invoiceData!
                                          .invoice.outstandingAmount),
                                      icon: Icons.account_balance_wallet,
                                      valueColor: _invoiceData!
                                                  .invoice.outstandingAmount ==
                                              0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// 📊 TOTAL QUANTITY CARD
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: _buildInfoCard(
                                title: "Total Items",
                                value: "${_invoiceData!.items.length} Items",
                                icon: Icons.inventory_2,
                                valueColor: Colors.black87,
                                isFullWidth: true,
                              ),
                            ),

                            const SizedBox(height: 16),

                            /// 📦 ITEMS SECTION HEADER
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(31, 40, 55, 1)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.list_alt,
                                      color: Color.fromRGBO(31, 40, 55, 1),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Items Details",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            /// 📋 ITEMS LIST
                            _invoiceData!.items.isEmpty
                                ? Container(
                                    margin: const EdgeInsets.all(16),
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.inbox_outlined,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'Aucun article',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _invoiceData!.items.length,
                                    itemBuilder: (context, index) {
                                      final item = _invoiceData!.items[index];
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 6),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.1),
                                              spreadRadius: 1,
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        item.itemName,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.grey
                                                              .shade100,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: Text(
                                                          item.itemCode,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .grey.shade700,
                                                            fontFamily:
                                                                'monospace',
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: const Color.fromRGBO(
                                                            31, 40, 55, 1)
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    _formatCurrency(
                                                        item.amount),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color.fromRGBO(
                                                          31, 40, 55, 1),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            const Divider(height: 1),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildItemDetail(
                                                    icon: Icons.shopping_cart,
                                                    label: "Quantity",
                                                    value: item.qty
                                                        .toStringAsFixed(0),
                                                  ),
                                                ),
                                                Container(
                                                  width: 1,
                                                  height: 40,
                                                  color: Colors.grey.shade200,
                                                ),
                                                Expanded(
                                                  child: _buildItemDetail(
                                                    icon: Icons.payment,
                                                    label: "Rate",
                                                    value: _formatCurrency(
                                                        item.rate),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color valueColor,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}