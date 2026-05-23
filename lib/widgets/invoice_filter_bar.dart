import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../application/controllers/invoice_controller.dart';
import '../../application/controllers/language_controller.dart';

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

    return GetBuilder<LanguageController>(
      builder: (_) => Container(
        color: const Color.fromRGBO(254, 255, 255, 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
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
                  decoration: InputDecoration(
                    hintText: 'search_by_number'.tr,
                    prefixIcon: const Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
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
                  items: [
                    DropdownMenuItem(value: 'All',     child: Text('filter_all'.tr)),
                    DropdownMenuItem(value: 'Paid',    child: Text('filter_paid'.tr)),
                    DropdownMenuItem(value: 'Overdue', child: Text('filter_overdue'.tr)),
                  ],
                  onChanged: onStatusChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
