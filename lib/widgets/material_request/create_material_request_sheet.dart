import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../../presentation/controllers/material_request_controller.dart';
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
  DateTime _requiredBy = DateTime.now().add(const Duration(days: 7));

  String? _sourceWarehouse;
  String? _targetWarehouse;

  String? _selectedPriceList;
  List<String> _priceLists = [];
  List<String> _companies = ['OPTILENS ALGER'];

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _searchResults = [];
  bool _isSearchingItems = false;

  final List<Map<String, dynamic>> _selectedItems = [];
  bool _isSaving = false;
  bool _isSubmitting = false;

  final _purposes = [
    'Material Transfer',
    'Material Issue',
    'Material Receipt',
    'Purchase',
  ];

  @override
  void dispose() {
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

  Future<void> _search(String text) async {
    if (text.isEmpty) {
      setState(() => _searchResults.clear());
      return;
    }
    setState(() => _isSearchingItems = true);
    final res = await widget.c.searchItems(text);
    setState(() {
      _searchResults = res;
      _isSearchingItems = false;
    });
  }

  void _addItem(Map<String, String> itemData) {
    final idx = _selectedItems
        .indexWhere((i) => i['item_code'] == itemData['item_code']);
    if (idx >= 0) {
      setState(() {
        _selectedItems[idx]['qty'] = (_selectedItems[idx]['qty'] as int) + 1;
      });
    } else {
      setState(() {
        _selectedItems.add({
          'item_code': itemData['item_code'],
          'item_name': itemData['item_name'],
          'qty': 1,
        });
      });
    }
    _searchController.clear();
    setState(() => _searchResults.clear());
  }

  Future<void> _submit({required bool submitDirect}) async {
    if (_selectedItems.isEmpty) {
      Get.snackbar('error'.tr, 'mr_add_item_required'.tr,
          backgroundColor: Colors.red.shade100, colorText: Colors.red);
      return;
    }

    if (_selectedPurpose == 'Material Transfer') {
      if (_sourceWarehouse == null || _targetWarehouse == null) {
        Get.snackbar('error'.tr, 'mr_select_both_warehouses'.tr,
            backgroundColor: Colors.red.shade100, colorText: Colors.red);
        return;
      }
    } else if (_selectedPurpose == 'Material Issue') {
      if (_sourceWarehouse == null) {
        Get.snackbar('error'.tr, 'mr_select_source_warehouse'.tr,
            backgroundColor: Colors.red.shade100, colorText: Colors.red);
        return;
      }
    } else if (_selectedPurpose == 'Material Receipt' ||
        _selectedPurpose == 'Purchase') {
      if (_targetWarehouse == null) {
        Get.snackbar('error'.tr, 'mr_select_target_warehouse'.tr,
            backgroundColor: Colors.red.shade100, colorText: Colors.red);
        return;
      }
    }

    if (submitDirect) {
      setState(() => _isSubmitting = true);
    } else {
      setState(() => _isSaving = true);
    }

    final requiredByStr =
        '${_requiredBy.year}-${_requiredBy.month.toString().padLeft(2, '0')}-${_requiredBy.day.toString().padLeft(2, '0')}';

    final itemsPayload = _selectedItems
        .map((e) => {
              'item_code': e['item_code'],
              'qty': e['qty'],
            })
        .toList();

    String setWarehouse = '';
    String? setFromWarehouse;
    if (_selectedPurpose == 'Material Transfer') {
      setWarehouse = _targetWarehouse!;
      setFromWarehouse = _sourceWarehouse;
    } else if (_selectedPurpose == 'Material Issue') {
      setWarehouse = _sourceWarehouse!;
    } else {
      setWarehouse = _targetWarehouse!;
    }

    final res = await widget.c.createRequest(
      company: _selectedCompany,
      purpose: _selectedPurpose,
      requiredBy: requiredByStr,
      setWarehouse: setWarehouse,
      setFromWarehouse: setFromWarehouse,
      priceList: _selectedPriceList,
      items: itemsPayload,
    );

    if (res.isAuthHandled) {
      if (submitDirect) {
        setState(() => _isSubmitting = false);
      } else {
        setState(() => _isSaving = false);
      }
      return;
    }
    if (!res.isSuccess) {
      if (submitDirect) {
        setState(() => _isSubmitting = false);
      } else {
        setState(() => _isSaving = false);
      }
      Get.snackbar('error'.tr, res.error ?? 'error_occurred'.tr,
          backgroundColor: Colors.red.shade100, colorText: Colors.red);
      return;
    }

    final newDocName = res.documentName;

    if (submitDirect && newDocName != null) {
      final submitRes = await widget.c.submitRequest(newDocName);
      setState(() => _isSubmitting = false);

      if (submitRes.isAuthHandled) {
        Get.back();
        widget.c.onRefresh();
        return;
      }
      if (!submitRes.isSuccess) {
        Get.snackbar(
            'warning'.tr, '${'mr_draft_submit_failed'.tr}: ${submitRes.error}',
            backgroundColor: Colors.orange.shade100,
            colorText: Colors.orange.shade900);
      } else {
        Get.snackbar('success'.tr, 'mr_submitted'.tr,
            backgroundColor: Colors.green.shade100, colorText: Colors.green);
      }
    } else {
      setState(() => _isSaving = false);
      Get.snackbar('success'.tr, 'mr_created'.tr,
          backgroundColor: Colors.green.shade100, colorText: Colors.green);
    }

    Get.back();
    widget.c.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('create_mr_title'.tr,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
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
                  controller: controller,
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 8,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  children: [
                    if (_companies.length > 1) ...[
                      MrLabeledField(
                        label: 'select_company'.tr,
                        child: MrDropdownShell(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedCompany,
                            items: _companies
                                .map((c) =>
                                    DropdownMenuItem(value: c, child: Text(c)))
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
                      const SizedBox(height: 16),
                    ],
                    MrLabeledField(
                      label: 'purpose'.tr,
                      child: MrDropdownShell(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedPurpose,
                          items: _purposes
                              .map((p) =>
                                  DropdownMenuItem(value: p, child: Text(p)))
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
                    const SizedBox(height: 16),
                    MrLabeledField(
                      label: 'required_by'.tr,
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _requiredBy,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (ctx, child) => Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.primary,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (date != null) setState(() => _requiredBy = date);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.scaffold,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: AppColors.primary, size: 18),
                              const SizedBox(width: 10),
                              Text(
                                '${_requiredBy.year}-${_requiredBy.month.toString().padLeft(2, '0')}-${_requiredBy.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 20),
                    MrLabeledField(
                      label: 'items_title'.tr.isNotEmpty
                          ? 'items_title'.tr
                          : 'items_label'.tr,
                      child: MrItemSearch(
                        searchController: _searchController,
                        isSearching: _isSearchingItems,
                        results: _searchResults,
                        onChanged: _search,
                        onAdd: _addItem,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      final whList = widget.c.warehouses.toList();
                      if (whList.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedPurpose == 'Material Transfer' ||
                              _selectedPurpose == 'Material Issue') ...[
                            MrLabeledField(
                              label: 'source_warehouse'.tr,
                              child: MrDropdownShell(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: Text('select_warehouse'.tr),
                                  value: _sourceWarehouse,
                                  items: whList
                                      .map((w) => DropdownMenuItem(
                                          value: w['name'],
                                          child: Text(w['warehouse_name'] ??
                                              w['name'] ??
                                              '')))
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() => _sourceWarehouse = v);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_selectedPurpose == 'Material Transfer' ||
                              _selectedPurpose == 'Material Receipt' ||
                              _selectedPurpose == 'Purchase') ...[
                            MrLabeledField(
                              label: 'target_warehouse'.tr,
                              child: MrDropdownShell(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: Text('select_warehouse'.tr),
                                  value: _targetWarehouse,
                                  items: whList
                                      .map((w) => DropdownMenuItem(
                                          value: w['name'],
                                          child: Text(w['warehouse_name'] ??
                                              w['name'] ??
                                              '')))
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() => _targetWarehouse = v);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      );
                    }),
                    ..._selectedItems.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return MrSelectedItemTile(
                        item: item,
                        onDecrement: () => setState(() {
                          if (item['qty'] > 1) {
                            item['qty']--;
                          } else {
                            _selectedItems.removeAt(idx);
                          }
                        }),
                        onIncrement: () => setState(() => item['qty']++),
                        onRemove: () =>
                            setState(() => _selectedItems.removeAt(idx)),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (_isSaving || _isSubmitting)
                            ? null
                            : () => _submit(submitDirect: false),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.teal, strokeWidth: 2))
                            : const Icon(Icons.save, color: Colors.teal),
                        label: Text('save_draft'.tr,
                            style: const TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade50,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.teal)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (_isSaving || _isSubmitting)
                            ? null
                            : () => _submit(submitDirect: true),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
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
            ],
          ),
        );
      },
    );
  }
}
