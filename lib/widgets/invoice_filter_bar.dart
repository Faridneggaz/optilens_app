import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../application/controllers/invoice_controller.dart';

class InvoiceFilterBar extends StatelessWidget {
  final void Function(String) onSearchChanged;
  final void Function(String?) onStatusChanged;
  final String selectedStatus;

  const InvoiceFilterBar({
    super.key,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.selectedStatus,
  });

  @override
  Widget build(BuildContext context) {
    final c = Get.find<InvoiceController>();

    return Container(
      color: const Color.fromRGBO(254, 255, 255, 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: c.searchController,
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search by number',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                icon: const Icon(Icons.filter_list),
                value: selectedStatus,
                items: ['All', 'Paid', 'Overdue']
                    .map(
                      (status) =>
                          DropdownMenuItem(value: status, child: Text(status)),
                    )
                    .toList(),
                onChanged: onStatusChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
