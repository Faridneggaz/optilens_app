import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../../presentation/controllers/material_request_controller.dart';
import '../../utils/mr_status_helper.dart';
import 'mr_form_widgets.dart';

class CreateMaterialRequestSheet extends StatefulWidget {
  final MaterialRequestController c;
  const CreateMaterialRequestSheet({super.key, required this.c});

  @override
  State<CreateMaterialRequestSheet> createState() =>
      CreateMaterialRequestSheetState();
}

class CreateMaterialRequestSheetState
    extends State<CreateMaterialRequestSheet> {
  String _selectedCompany = 'OPTILENS ALGER';
  String _selectedPurpose = 'Material Transfer';
  DateTime _transactionDate = DateTime.now();
  DateTime _requiredBy = DateTime.now().add(const Duration(days: 7));

  String? _sourceWarehouse;
  String? _targetWarehouse;

  String? _selectedPriceList;
  List<String> _priceLists = [];
  List<String> _companies = ['OPTILENS ALGER'];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<Map<String, String>> _searchResults = [];
  bool _isSearchingItems = false;
  Timer? _searchDebounce;
  int _searchSeq = 0;

  final List<Map<String, dynamic>> _selectedItems = [];
  bool _isSaving = false;
  bool _isSubmitting = false;
  String? _formError;
  String? _savedDocName;

  final _purposes = materialRequestPurposes;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initLookups();
  }

  Future<void> _initLookups() async {
    final session = Get.find<SessionService>();
    final allowed = session.getAllowedCompanies();
    if (allowed.isNotEmpty) {
      _companies = allowed;
      if (!_companies.contains(_selectedCompany)) {
        _selectedCompany = _companies.first;
      }
    }

    await Future.wait([
      widget.c.loadCompanies(),
      widget.c.loadPriceLists(),
    ]);
    if (!mounted) return;

    setState(() {
      if (widget.c.companies.isNotEmpty) {
        _companies = widget.c.companies.toList();
        if (!_companies.contains(_selectedCompany)) {
          _selectedCompany = _companies.first;
        }
      }
      _priceLists = widget.c.priceLists.toList();
      if (_selectedPriceList != null &&
          !_priceLists.contains(_selectedPriceList)) {
        _selectedPriceList = null;
      }
    });
    await widget.c.loadWarehouses(_selectedCompany);
  }

  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    final q = text.trim();
    if (q.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearchingItems = false;
      });
      return;
    }
    setState(() => _isSearchingItems = true);
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      _search(q);
    });
  }

  Future<void> _search(String text) async {
    final seq = ++_searchSeq;
    final res = await widget.c.searchItems(text);
    if (!mounted || seq != _searchSeq) return;
    setState(() {
      _searchResults = res;
      _isSearchingItems = false;
    });
  }

  int _itemQty(Map<String, dynamic> item) {
    final q = item['qty'];
    if (q is num) return q.toInt();
    return int.tryParse('$q') ?? 1;
  }

  void _addItem(Map<String, String> itemData) {
    final code = itemData['item_code'] ?? '';
    if (code.isEmpty) return;
    final idx = _selectedItems.indexWhere((i) => i['item_code'] == code);
    setState(() {
      if (idx >= 0) {
        _selectedItems[idx]['qty'] = _itemQty(_selectedItems[idx]) + 1;
      } else {
        _selectedItems.add({
          'item_code': code,
          'item_name': itemData['item_name'] ?? code,
          'qty': 1,
        });
      }
      _searchResults.clear();
    });
    _searchController.clear();
    _searchFocus.unfocus();
  }

  bool _validateForm() {
    setState(() => _formError = null);
    if (_selectedItems.isEmpty) {
      setState(() => _formError = 'mr_add_item_required'.tr);
      return false;
    }
    if (_selectedPurpose == 'Material Transfer') {
      if (_sourceWarehouse == null || _targetWarehouse == null) {
        setState(() => _formError = 'mr_select_both_warehouses'.tr);
        return false;
      }
      if (_sourceWarehouse == _targetWarehouse) {
        setState(() => _formError = 'mr_same_warehouse'.tr);
        return false;
      }
    } else if (needsSourceWarehouse(_selectedPurpose) &&
        _sourceWarehouse == null) {
      setState(() => _formError = 'mr_select_source_warehouse'.tr);
      return false;
    } else if (needsTargetWarehouse(_selectedPurpose) &&
        _targetWarehouse == null) {
      setState(() => _formError = 'mr_select_target_warehouse'.tr);
      return false;
    }
    return true;
  }

  List<Map<String, dynamic>> _itemsPayload() {
    return _selectedItems.map((e) {
      final row = <String, dynamic>{
        'item_code': e['item_code'],
        'qty': e['qty'],
      };
      if (_selectedPurpose == 'Material Transfer') {
        row['warehouse'] = _targetWarehouse;
        row['from_warehouse'] = _sourceWarehouse;
      } else if (_selectedPurpose == 'Material Issue') {
        row['warehouse'] = _sourceWarehouse;
        row['from_warehouse'] = _sourceWarehouse;
      } else {
        row['warehouse'] = _targetWarehouse;
      }
      return row;
    }).toList();
  }

  Future<void> _saveDraft() async {
    if (_savedDocName != null) return;
    if (!_validateForm()) return;

    setState(() => _isSaving = true);
    final requiredByStr =
        '${_requiredBy.year}-${_requiredBy.month.toString().padLeft(2, '0')}-${_requiredBy.day.toString().padLeft(2, '0')}';

    String setWarehouse = '';
    String? setFromWarehouse;
    if (_selectedPurpose == 'Material Transfer') {
      setWarehouse = _targetWarehouse!;
      setFromWarehouse = _sourceWarehouse;
    } else if (_selectedPurpose == 'Material Issue') {
      setFromWarehouse = _sourceWarehouse;
      setWarehouse = _sourceWarehouse!;
    } else {
      setWarehouse = _targetWarehouse!;
    }

    try {
      final res = await widget.c.createRequest(
        company: _selectedCompany,
        purpose: _selectedPurpose,
        requiredBy: requiredByStr,
        setWarehouse: setWarehouse,
        setFromWarehouse: setFromWarehouse,
        priceList: _selectedPriceList,
        items: _itemsPayload(),
      );
      if (!mounted) return;
      if (res.isAuthHandled) return;
      if (!res.isSuccess) {
        setState(() => _formError = res.error ?? 'error_occurred'.tr);
        return;
      }
      final name = res.documentName;
      if (name == null || name.isEmpty) {
        setState(() => _formError = 'error_occurred'.tr);
        return;
      }
      setState(() => _savedDocName = name);
      widget.c.onRefresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _formError = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitSaved() async {
    final name = _savedDocName;
    if (name == null) return;
    setState(() {
      _formError = null;
      _isSubmitting = true;
    });
    try {
      final submitRes = await widget.c.submitRequest(name);
      if (!mounted) return;
      if (submitRes.isAuthHandled) {
        Get.back();
        widget.c.onRefresh();
        return;
      }
      if (!submitRes.isSuccess) {
        setState(() => _formError = submitRes.error ?? 'error_occurred'.tr);
        return;
      }
      Get.back();
      widget.c.onRefresh();
      Get.snackbar('success'.tr, 'mr_submitted'.tr,
          backgroundColor: Colors.green.shade100, colorText: Colors.green);
    } catch (e) {
      if (!mounted) return;
      setState(() => _formError = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.92;
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('create_mr_title'.tr,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'not_saved'.tr,
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    )
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    MrSectionCard(
                      title: 'mr_details_section'.tr,
                      children: [
                        if (_companies.length > 1) ...[
                          MrLabeledField(
                            label: 'select_company'.tr,
                            required: true,
                            child: MrDropdownShell(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedCompany,
                                items: _companies
                                    .map((c) => DropdownMenuItem(
                                        value: c, child: Text(c)))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _selectedCompany = v);
                                    widget.c.loadWarehouses(v);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        MrLabeledField(
                          label: 'purpose'.tr,
                          required: true,
                          child: MrDropdownShell(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedPurpose,
                              items: _purposes
                                  .map((p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(translateMRPurpose(p)),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _selectedPurpose = v;
                                    _sourceWarehouse = null;
                                    _targetWarehouse = null;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: MrLabeledField(
                                label: 'transaction_date'.tr,
                                required: true,
                                child: MrDateField(
                                  value: _transactionDate,
                                  onChanged: (d) =>
                                      setState(() => _transactionDate = d),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: MrLabeledField(
                                label: 'required_by'.tr,
                                required: true,
                                child: MrDateField(
                                  value: _requiredBy,
                                  onChanged: (d) =>
                                      setState(() => _requiredBy = d),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        MrLabeledField(
                          label: 'price_list'.tr,
                          child: MrDropdownShell(
                            child: DropdownButton<String>(
                              value: _selectedPriceList,
                              isExpanded: true,
                              hint: Text('select_price_list'.tr,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 14)),
                              items: [
                                DropdownMenuItem(
                                    value: null, child: Text('none'.tr)),
                                ..._priceLists.map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p,
                                        style: const TextStyle(fontSize: 14))))
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedPriceList = v),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Obx(() {
                      final whList = widget.c.warehouses
                          .where((w) => (w['name'] ?? '').isNotEmpty)
                          .toList();
                      final names = whList.map((w) => w['name']!).toSet();
                      final sourceValue =
                          names.contains(_sourceWarehouse) ? _sourceWarehouse : null;
                      final targetValue =
                          names.contains(_targetWarehouse) ? _targetWarehouse : null;
                      if (!needsSourceWarehouse(_selectedPurpose) &&
                          !needsTargetWarehouse(_selectedPurpose)) {
                        return const SizedBox.shrink();
                      }
                      final items = whList
                          .map<DropdownMenuItem<String>>((w) => DropdownMenuItem(
                                value: w['name'],
                                child: Text(
                                    w['warehouse_name'] ?? w['name'] ?? ''),
                              ))
                          .toList();
                      return MrSectionCard(
                        title: 'mr_warehouses_section'.tr,
                        children: [
                          if (needsSourceWarehouse(_selectedPurpose)) ...[
                            MrLabeledField(
                              label: 'source_warehouse'.tr,
                              required: true,
                              child: MrDropdownShell(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: Text('select_warehouse'.tr),
                                  value: sourceValue,
                                  items: items,
                                  onChanged: (v) {
                                    setState(() => _sourceWarehouse = v);
                                  },
                                ),
                              ),
                            ),
                            if (needsTargetWarehouse(_selectedPurpose))
                              const SizedBox(height: 14),
                          ],
                          if (needsTargetWarehouse(_selectedPurpose))
                            MrLabeledField(
                              label: 'target_warehouse'.tr,
                              required: true,
                              child: MrDropdownShell(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: Text('select_warehouse'.tr),
                                  value: targetValue,
                                  items: items,
                                  onChanged: (v) {
                                    setState(() => _targetWarehouse = v);
                                  },
                                ),
                              ),
                            ),
                        ],
                      );
                    }),
                    const SizedBox(height: 8),
                    _buildItemsPicker(),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_formError != null) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _formError!,
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (_savedDocName != null) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            '${'mr_saved_draft'.tr}: $_savedDocName',
                            style: TextStyle(
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (_savedDocName == null)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isSaving ? null : _saveDraft,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.teal, strokeWidth: 2))
                                : const Icon(Icons.save, color: Colors.teal),
                            label: Text('save_draft'.tr,
                                style: const TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Colors.teal),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _submitSaved,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.send, color: Colors.white),
                            label: Text('submit_direct'.tr,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildItemsPicker() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      decoration: BoxDecoration(
        color: AppColors.scaffold,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: 'items_title'.tr,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
              children: [
                const TextSpan(
                  text: ' *',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
                ),
                if (_selectedItems.isNotEmpty)
                  TextSpan(
                    text: ' (${_selectedItems.length})',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          MrItemSearchField(
            searchController: _searchController,
            focusNode: _searchFocus,
            isSearching: _isSearchingItems,
            onChanged: _onSearchChanged,
          ),
          MrItemResultsBox(
            results: _searchResults,
            onAdd: _addItem,
            maxHeight: 180,
          ),
          if (!_isSearchingItems &&
              _searchController.text.trim().isNotEmpty &&
              _searchResults.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'no_item_found'.tr,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          if (_selectedItems.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                'mr_add_item_required'.tr,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            )
          else
            ..._selectedItems.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return MrSelectedItemTile(
                item: item,
                onDecrement: () => setState(() {
                  final qty = _itemQty(item);
                  if (qty > 1) {
                    item['qty'] = qty - 1;
                  } else {
                    _selectedItems.removeAt(idx);
                  }
                }),
                onIncrement: () => setState(() {
                  item['qty'] = _itemQty(item) + 1;
                }),
                onRemove: () => setState(() => _selectedItems.removeAt(idx)),
              );
            }),
        ],
      ),
    );
  }
}
