import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../presentation/controllers/commande_manque_controller.dart';

class ManquePickRow {
  const ManquePickRow({
    required this.code,
    required this.title,
    this.subtitle = '',
  });

  final String code;
  final String title;
  final String subtitle;
}

Future<ManquePickRow?> showManqueLocalPicker({
  required BuildContext context,
  required String title,
  required String hint,
  required List<ManquePickRow> rows,
  required String emptyLabel,
}) {
  return showModalBottomSheet<ManquePickRow>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => ManqueLocalPickerSheet(
      title: title,
      hint: hint,
      rows: rows,
      emptyLabel: emptyLabel,
    ),
  );
}

Future<ManquePickRow?> showManqueCustomerPicker({
  required BuildContext context,
  required String company,
  required CommandeManqueController controller,
}) {
  return showModalBottomSheet<ManquePickRow>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => ManqueCustomerPickerSheet(
      company: company,
      controller: controller,
    ),
  );
}

class ManqueLocalPickerSheet extends StatefulWidget {
  const ManqueLocalPickerSheet({
    super.key,
    required this.title,
    required this.hint,
    required this.rows,
    required this.emptyLabel,
  });

  final String title;
  final String hint;
  final List<ManquePickRow> rows;
  final String emptyLabel;

  @override
  State<ManqueLocalPickerSheet> createState() => _ManqueLocalPickerSheetState();
}

class _ManqueLocalPickerSheetState extends State<ManqueLocalPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final shown = q.isEmpty
        ? widget.rows
        : widget.rows
            .where(
              (r) =>
                  r.title.toLowerCase().contains(q) ||
                  r.subtitle.toLowerCase().contains(q) ||
                  r.code.toLowerCase().contains(q),
            )
            .toList();
    return _ManquePickerScaffold(
      title: widget.title,
      hint: widget.hint,
      onQuery: (v) => setState(() => _q = v),
      child: shown.isEmpty
          ? Center(child: Text(widget.emptyLabel))
          : ListView.builder(
              itemCount: shown.length,
              itemBuilder: (_, i) {
                final row = shown[i];
                return ListTile(
                  title: Text(row.title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: row.subtitle.trim().isEmpty
                      ? null
                      : Text(row.subtitle),
                  onTap: () => Navigator.pop(context, row),
                );
              },
            ),
    );
  }
}

class ManqueCustomerPickerSheet extends StatefulWidget {
  const ManqueCustomerPickerSheet({
    super.key,
    required this.company,
    required this.controller,
  });

  final String company;
  final CommandeManqueController controller;

  @override
  State<ManqueCustomerPickerSheet> createState() =>
      _ManqueCustomerPickerSheetState();
}

class _ManqueCustomerPickerSheetState extends State<ManqueCustomerPickerSheet> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQuery(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      widget.controller.loadCustomers(widget.company, search: q);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ManquePickerScaffold(
      title: 'manque_customer'.tr,
      hint: 'manque_search_customer'.tr,
      onQuery: _onQuery,
      child: Obx(() {
        final loading = widget.controller.customersLoading.value;
        final rows = widget.controller.customers;
        if (loading && rows.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (rows.isEmpty) {
          return Center(child: Text('manque_no_customers'.tr));
        }
        return ListView.builder(
          itemCount: rows.length,
          itemBuilder: (_, i) {
            final c = rows[i];
            return ListTile(
              title: Text(c.name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle:
                  c.customerName.isEmpty ? null : Text(c.customerName),
              onTap: () => Navigator.pop(
                context,
                ManquePickRow(
                  code: c.name,
                  title: c.name,
                  subtitle: c.customerName,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _ManquePickerScaffold extends StatelessWidget {
  const _ManquePickerScaffold({
    required this.title,
    required this.hint,
    required this.onQuery,
    required this.child,
  });

  final String title;
  final String hint;
  final ValueChanged<String> onQuery;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                onChanged: onQuery,
                decoration: InputDecoration(
                  hintText: hint,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
