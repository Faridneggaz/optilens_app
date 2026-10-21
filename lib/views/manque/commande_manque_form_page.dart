import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/manque.dart';
import '../../presentation/controllers/commande_manque_controller.dart';
import '../../presentation/controllers/language_controller.dart';
import '../../widgets/header.dart';
import '../../widgets/manque/manque_pickers.dart';
import '../../widgets/manque/manque_widgets.dart';
import '../../widgets/material_request/mr_form_widgets.dart';
import '../../widgets/material_request/pick_mr_items_sheet.dart';
import '../../widgets/stock/document_ui.dart';

class CommandeManqueFormPage extends StatefulWidget {
  const CommandeManqueFormPage({super.key});

  @override
  State<CommandeManqueFormPage> createState() => _CommandeManqueFormPageState();
}

class _CommandeManqueFormPageState extends State<CommandeManqueFormPage> {
  final _c = Get.find<CommandeManqueController>();

  String _company = '';
  String? _warehouse;
  String? _buyer;
  String? _customer;
  String _customerName = '';
  DateTime _date = DateTime.now();
  final _lines = <CommandeManqueItem>[];
  bool _saving = false;
  String? _error;
  final _customerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _c.loadLookups();
      if (!mounted) return;
      final company =
          _c.companies.isNotEmpty ? _c.companies.first : 'OPTILENS ALGER';
      setState(() => _company = company);
      await _applyCompany(company, keepWarehouse: true);
    });
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String get _buyerName {
    final code = _buyer;
    if (code == null || code.isEmpty) return '';
    final match = _c.buyers.where((b) => b.name == code);
    if (match.isEmpty) return '';
    return match.first.displayName;
  }

  String get _buyerFiche {
    final code = _buyer;
    if (code == null || code.isEmpty) return '';
    final match = _c.buyers.where((b) => b.name == code);
    if (match.isEmpty) return '';
    return match.first.ficheDePoste;
  }

  Future<void> _applyCompany(String company, {bool keepWarehouse = false}) async {
    if (!keepWarehouse) {
      setState(() {
        _warehouse = null;
        _customer = null;
        _customerName = '';
      });
    }
    await Future.wait([
      _c.loadWarehouses(company),
      _c.loadCustomers(company),
    ]);
    if (!mounted) return;
    setState(() {
      if (_c.warehouses.length == 1) {
        _warehouse = _c.warehouses.first['name'];
      } else if (!keepWarehouse ||
          !_c.warehouses.any((w) => w['name'] == _warehouse)) {
        _warehouse = null;
      }
    });
  }

  Future<void> _openItemPicker() async {
    final selected = _lines
        .map(
          (e) => <String, dynamic>{
            'item_code': e.itemCode,
            'item_name': e.itemName,
            'qty': e.qty.round(),
            'uom': e.uom,
          },
        )
        .toList();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PickMrItemsSheet(
        searchItems: _c.searchItems,
        selectedItems: selected,
        onAdd: (item, qty) {
          final code = (item['item_code'] ?? '').trim();
          if (code.isEmpty) return;
          final addQty = qty < 1 ? 1 : qty;
          final idx = selected.indexWhere((r) => r['item_code'] == code);
          if (idx >= 0) {
            final current = selected[idx]['qty'];
            final base = current is num
                ? current.toInt()
                : int.tryParse('$current') ?? 0;
            selected[idx]['qty'] = base + addQty;
          } else {
            selected.add({
              'item_code': code,
              'item_name': (item['item_name'] ?? code).trim(),
              'qty': addQty,
              'uom': item['stock_uom'] ?? item['uom'] ?? '',
            });
          }
        },
        onQtyChanged: (code, qty) {
          final idx = selected.indexWhere((r) => r['item_code'] == code);
          if (idx < 0) return;
          selected[idx]['qty'] = qty < 1 ? 1 : qty;
        },
        onRemove: (code) {
          selected.removeWhere((r) => r['item_code'] == code);
        },
      ),
    );
    if (!mounted) return;
    setState(() {
      _lines
        ..clear()
        ..addAll(
          selected.map((row) {
            final qty = row['qty'];
            final n = qty is num ? qty.toDouble() : double.tryParse('$qty') ?? 1;
            return CommandeManqueItem(
              itemCode: '${row['item_code'] ?? ''}',
              itemName: '${row['item_name'] ?? ''}',
              qty: n <= 0 ? 1 : n,
              uom: '${row['uom'] ?? ''}',
            );
          }),
        );
      _error = null;
    });
  }

  String _qtyLabel(double qty) {
    if (qty == qty.roundToDouble()) return qty.toInt().toString();
    return qty.toString();
  }

  Future<void> _submit({required bool envoyer}) async {
    if (_company.isEmpty ||
        (_warehouse ?? '').isEmpty ||
        (_buyer ?? '').isEmpty ||
        (_customer ?? '').isEmpty) {
      setState(() => _error = 'manque_form_incomplete'.tr);
      return;
    }
    if (_lines.isEmpty) {
      setState(() => _error = 'manque_items_required'.tr);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await _c.createCommande(
      company: _company,
      warehouse: _warehouse!,
      buyer: _buyer!,
      customer: _customer!,
      customerName: _customerName,
      transactionDate: _fmt(_date),
      lineItems: _lines
          .map((e) => {'item_code': e.itemCode, 'qty': e.qty})
          .toList(),
      envoyer: envoyer,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.isAuthHandled ||
        (result.error?.toLowerCase().contains('access denied') ?? false)) {
      _c.canCreate.value = false;
      if (!result.isAuthHandled) {
        setState(() => _error = result.error ?? 'error_occurred'.tr);
      }
      return;
    }
    if (result.isSuccess) {
      setState(() {
        _lines.clear();
        _customer = null;
        _customerName = '';
      });
      Get.snackbar(
        'success'.tr,
        'manque_sent_next'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final target = _customerKey.currentContext;
        if (target != null) {
          Scrollable.ensureVisible(
            target,
            duration: const Duration(milliseconds: 250),
            alignment: 0.05,
          );
        }
      });
      return;
    }
    setState(() => _error = result.error ?? 'error_occurred'.tr);
  }

  Future<void> _pickWarehouse() async {
    final rows = _c.warehouses
        .map(
          (w) => ManquePickRow(
            code: w['name'] ?? '',
            title: w['name'] ?? '',
            subtitle: (w['warehouse_name'] ?? '').trim(),
          ),
        )
        .where((r) => r.code.isNotEmpty)
        .toList();
    final picked = await showManqueLocalPicker(
      context: context,
      title: 'warehouse'.tr,
      hint: 'manque_search_warehouse'.tr,
      rows: rows,
      emptyLabel: 'manque_pick_warehouse'.tr,
    );
    if (picked == null || !mounted) return;
    setState(() => _warehouse = picked.code);
  }

  Future<void> _pickBuyer() async {
    final rows = _c.buyers
        .map(
          (b) => ManquePickRow(
            code: b.name,
            title: b.displayName,
            subtitle: b.ficheDePoste,
          ),
        )
        .toList();
    final picked = await showManqueLocalPicker(
      context: context,
      title: 'manque_buyer'.tr,
      hint: 'manque_search_buyer'.tr,
      rows: rows,
      emptyLabel: 'manque_no_buyers'.tr,
    );
    if (picked == null || !mounted) return;
    setState(() => _buyer = picked.code);
  }

  Future<void> _pickCustomer() async {
    if (_company.isEmpty) return;
    await _c.loadCustomers(_company);
    if (!mounted) return;
    final picked = await showManqueCustomerPicker(
      context: context,
      company: _company,
      controller: _c,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _customer = picked.code;
      _customerName = picked.subtitle;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LanguageController>(
      builder: (_) => Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Column(
          children: [
            AppHeader(
              title: 'manque_new_commande'.tr,
              customer: null,
              customerCode: '',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Obx(() {
                    final companies = _c.companies;
                    return MrLabeledField(
                      label: 'company'.tr,
                      required: true,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('co-${companies.join()}|$_company'),
                        initialValue: companies.contains(_company)
                            ? _company
                            : (companies.isNotEmpty ? companies.first : null),
                        items: companies
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) async {
                          if (v == null || v == _company) return;
                          setState(() => _company = v);
                          await _applyCompany(v);
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Obx(() {
                    final _ = _c.warehouses.length;
                    return MrLabeledField(
                      label: 'warehouse'.tr,
                      required: true,
                      child: ManqueCodeField(
                        code: _warehouse ?? '',
                        hint: 'manque_pick_warehouse'.tr,
                        enabled: _company.isNotEmpty,
                        onTap: _pickWarehouse,
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  MrLabeledField(
                    label: 'task_date'.tr,
                    child: InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setState(() => _date = d);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          suffixIcon: Icon(Icons.event),
                        ),
                        child: Text(_fmt(_date)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    final _ = _c.buyers.length;
                    return MrLabeledField(
                      label: 'manque_buyer'.tr,
                      required: true,
                      child: ManqueCodeField(
                        code: _buyerName,
                        caption: _buyerFiche,
                        hint: 'manque_pick_buyer'.tr,
                        onTap: _pickBuyer,
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Obx(() {
                    final ready = _company.isNotEmpty;
                    final loading = _c.customersLoading.value;
                    return MrLabeledField(
                      key: _customerKey,
                      label: 'manque_customer'.tr,
                      required: true,
                      child: ManqueCodeField(
                        code: _customer ?? '',
                        linkedName: _customerName,
                        hint: ready
                            ? (loading
                                ? '...'
                                : 'manque_pick_customer'.tr)
                            : 'manque_pick_company_first'.tr,
                        enabled: ready && !loading,
                        onTap: _pickCustomer,
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      text: 'manque_items'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                      children: [
                        if (_lines.isNotEmpty)
                          TextSpan(
                            text: ' (${_lines.length})',
                            style: const TextStyle(color: AppColors.primary),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _openItemPicker,
                      icon: const Icon(Icons.add_circle_outline,
                          color: AppColors.primary),
                      label: Text(
                        'add_item_dialog_title'.tr,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppColors.primary, width: 1.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._lines.map((line) {
                    final name = line.itemName.trim();
                    return DocumentItemLine(
                      code: line.itemCode,
                      name: name,
                      qty: 'Ã— ${_qtyLabel(line.qty)}',
                    );
                  }),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: DocumentPrimaryButton(
                  label: 'manque_send'.tr,
                  icon: Icons.send,
                  busy: _saving,
                  onPressed: _saving ? null : () => _submit(envoyer: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
