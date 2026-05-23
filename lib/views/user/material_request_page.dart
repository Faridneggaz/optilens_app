import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../application/controllers/material_request_controller.dart';
import '../../domain/response/material_request_response.dart';
import '../../widgets/header.dart';
import '../../../application/controllers/language_controller.dart';
import '../../app/routes/app_routes.dart';

class MaterialRequestPage extends StatelessWidget {
  const MaterialRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(MaterialRequestController());

    return GetBuilder<LanguageController>(
      builder: (_) => Scaffold(
        backgroundColor: const Color.fromARGB(255, 247, 255, 254),
        floatingActionButton: Obx(() {
          if (!c.isSearching.value) {
            return FloatingActionButton.extended(
              onPressed: () => _showCreateSheet(context, c),
              backgroundColor: const Color.fromARGB(255, 0, 167, 155),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text('new_request'.tr,
                  style: const TextStyle(color: Colors.white)),
            );
          }
          return const SizedBox.shrink();
        }),
        body: Column(
          children: [
            AppHeader(
                title: 'material_requests'.tr,
                customer: null,
                customerCode: ''),
            
            // Search & Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'search_mr_hint'.tr,
                                hintStyle: TextStyle(
                                    color: Colors.grey.shade400, fontSize: 13),
                                border: InputBorder.none,
                              ),
                              onChanged: (v) => c.searchQuery.value = v,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Obx(() => DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: c.selectedStatus.value,
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  color: Colors.grey),
                              items: [
                                'All',
                                'Draft',
                                'Pending',
                                'Submitted',
                                'Partially Received',
                                'Received',
                                'Cancelled',
                                'Stopped'
                              ].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value == 'All' ? 'Tous' : value,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  c.selectedStatus.value = v;
                                  c.onRefresh();
                                }
                              },
                            ),
                          )),
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: Obx(() {
                if (c.isLoading.value) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.teal));
                }

                if (c.isSearching.value) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.teal));
                }

                if (c.displayList.isEmpty) {
                  return Center(
                    child: Text('no_material_requests'.tr,
                        style: const TextStyle(color: Colors.grey)),
                  );
                }

                return RefreshIndicator(
                  onRefresh: c.onRefresh,
                  color: const Color.fromARGB(255, 0, 167, 155),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: c.displayList.length + 1,
                    itemBuilder: (context, index) {
                      if (index == c.displayList.length) {
                        return _buildLoadMoreButton(c);
                      }
                      return _buildRequestCard(
                          context, c.displayList[index], c);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton(MaterialRequestController c) {
    if (c.searchQuery.value.isNotEmpty || c.isSearching.value) {
      return const SizedBox.shrink();
    }
    if (!c.hasMore.value && c.materialRequests.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
            child: Text('all_entries_loaded'.tr,
                style: const TextStyle(color: Colors.grey))),
      );
    }
    if (c.isLoadingMore.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (c.hasMore.value && c.materialRequests.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ElevatedButton(
          onPressed: c.onLoadMore,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.teal,
            elevation: 0,
            side: const BorderSide(color: Colors.teal),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: Text('load_more'.tr,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildRequestCard(
    BuildContext context,
    MaterialRequest req,
    MaterialRequestController c,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.toNamed(AppRoutes.materialRequestDetail,
            arguments: req.name),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      req.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color.fromRGBO(31, 40, 55, 1),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(_translateStatus(req.status),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(req.status))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(req.transactionDate,
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(width: 12),
                  const Icon(Icons.business, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(req.company,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.warehouse_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                        req.fromWarehouse.isNotEmpty
                            ? '${req.fromWarehouse} → ${req.warehouse}'
                            : req.warehouse,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text(
                    '${req.items.length} item${req.items.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: Colors.teal,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (req.docstatus == 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleSubmit(context, req.name, c),
                        icon: const Icon(Icons.check, size: 16),
                        label: Text('submit'.tr),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _handleDelete(context, req.name, c),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: Text('delete'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'Draft':
        return 'Brouillon';
      case 'Submitted':
        return 'Soumis';
      case 'Pending':
        return 'En attente';
      case 'Partially Received':
        return 'Partiellement reçu';
      case 'Received':
        return 'Reçu';
      case 'Stopped':
        return 'Arrêté';
      case 'Cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Draft':
        return Colors.red;
      case 'Submitted':
        return Colors.blue;
      case 'Pending':
        return Colors.orange;
      case 'Partially Received':
      case 'Received':
        return Colors.green;
      case 'Stopped':
      case 'Cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _handleSubmit(
      BuildContext context, String name, MaterialRequestController c) {
    Get.defaultDialog(
      title: 'confirm_submit_mr'.tr,
      middleText: '',
      textConfirm: 'submit'.tr,
      textCancel: 'cancel'.tr,
      confirmTextColor: Colors.white,
      buttonColor: Colors.teal,
      onConfirm: () async {
        Get.back();
        Get.dialog(const Center(child: CircularProgressIndicator()),
            barrierDismissible: false);
        final res = await c.submitRequest(name);
        Get.back();
        if (res.containsKey('error')) {
          Get.snackbar('Error', res['error'],
              backgroundColor: Colors.red.shade100, colorText: Colors.red);
        } else {
          Get.snackbar('Success', 'mr_submitted'.tr,
              backgroundColor: Colors.green.shade100,
              colorText: Colors.green);
          c.onRefresh();
        }
      },
    );
  }

  void _handleDelete(
      BuildContext context, String name, MaterialRequestController c) {
    Get.defaultDialog(
      title: 'confirm_delete_mr'.tr,
      middleText: '',
      textConfirm: 'delete'.tr,
      textCancel: 'cancel'.tr,
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        Get.dialog(const Center(child: CircularProgressIndicator()),
            barrierDismissible: false);
        final res = await c.deleteRequest(name);
        Get.back();
        if (res.containsKey('error')) {
          Get.snackbar('Error', res['error'],
              backgroundColor: Colors.red.shade100, colorText: Colors.red);
        } else {
          Get.snackbar('Success', 'mr_deleted'.tr,
              backgroundColor: Colors.green.shade100,
              colorText: Colors.green);
          c.onRefresh();
        }
      },
    );
  }

  void _showCreateSheet(BuildContext context, MaterialRequestController c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateMaterialRequestSheet(c: c),
    );
  }
}

class _CreateMaterialRequestSheet extends StatefulWidget {
  final MaterialRequestController c;
  const _CreateMaterialRequestSheet({required this.c});

  @override
  State<_CreateMaterialRequestSheet> createState() =>
      _CreateMaterialRequestSheetState();
}

class _CreateMaterialRequestSheetState
    extends State<_CreateMaterialRequestSheet> {
  String _selectedCompany = 'OPTILENS ALGER';
  String _selectedPurpose = 'Material Transfer';
  DateTime _requiredBy = DateTime.now().add(const Duration(days: 7));
  
  String? _sourceWarehouse;
  String? _targetWarehouse;

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _searchResults = [];
  bool _isSearchingItems = false;

  final List<Map<String, dynamic>> _selectedItems = [];
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

  Future<void> _submit() async {
    if (_selectedItems.isEmpty) {
      Get.snackbar('Error', 'Please add at least one item',
          backgroundColor: Colors.red.shade100, colorText: Colors.red);
      return;
    }
    
    // Validation rules based on purpose
    if (_selectedPurpose == 'Material Transfer') {
      if (_sourceWarehouse == null || _targetWarehouse == null) {
        Get.snackbar('Error', 'Please select source and target warehouses',
            backgroundColor: Colors.red.shade100, colorText: Colors.red);
        return;
      }
    } else if (_selectedPurpose == 'Material Issue') {
      if (_sourceWarehouse == null) {
        Get.snackbar('Error', 'Please select source warehouse',
            backgroundColor: Colors.red.shade100, colorText: Colors.red);
        return;
      }
    } else if (_selectedPurpose == 'Material Receipt' || _selectedPurpose == 'Purchase') {
      if (_targetWarehouse == null) {
        Get.snackbar('Error', 'Please select target warehouse',
            backgroundColor: Colors.red.shade100, colorText: Colors.red);
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final String requiredByStr =
        "${_requiredBy.year}-${_requiredBy.month.toString().padLeft(2, '0')}-${_requiredBy.day.toString().padLeft(2, '0')}";

    final itemsPayload = _selectedItems.map((e) => {
      'item_code': e['item_code'],
      'qty': e['qty'],
    }).toList();

    // The setWarehouse should be target unless issue, then it's source? 
    // Wait, ERPNext standard: 
    // Material Transfer: set_warehouse = target, set_from_warehouse = source
    // Material Issue: set_warehouse = source (target empty) - wait, or is it set_from_warehouse? 
    // Usually Material Issue has `set_from_warehouse` or `set_warehouse`. Let's use set_warehouse as target, set_from_warehouse as source.
    // The prompt says: "Warehouse fields — DYNAMIC based on purpose: Material Transfer -> source + target. Material Issue -> source only. Material Receipt / Purchase -> target only."
    // And for create body: "set_warehouse (target - always required), set_from_warehouse (source - only for Material Transfer)".
    // So for Material Issue, is set_warehouse used for source? Yes, in ERPNext if it's Issue, `set_warehouse` acts as source warehouse.
    // Let's explicitly follow: setWarehouse is the main warehouse field, setFromWarehouse is the secondary.
    // Let's set it based on purpose:
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
      company:          _selectedCompany,
      purpose:          _selectedPurpose,
      requiredBy:       requiredByStr,
      setWarehouse:     setWarehouse,
      setFromWarehouse: setFromWarehouse,
      items:            itemsPayload,
    );

    setState(() => _isSubmitting = false);

    if (res.containsKey('error')) {
      Get.snackbar('Error', res['error'],
          backgroundColor: Colors.red.shade100, colorText: Colors.red);
    } else {
      Get.back(); // close sheet
      Get.snackbar('Success', 'mr_created'.tr,
          backgroundColor: Colors.green.shade100, colorText: Colors.green);
      widget.c.onRefresh();
    }
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
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('create_mr_title'.tr,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F2837))),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    )
                  ],
                ),
              ),
              const Divider(),

              // Form
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // ── Company ─────────────────────────────────────
                    Text('select_company'.tr,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedCompany,
                          items: ['OPTILENS ALGER']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
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

                    // ── Purpose ─────────────────────────────────────
                    Text('purpose'.tr,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
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

                    // ── Required By date picker ──────────────────────
                    Text('required_by'.tr,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _requiredBy,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                          builder: (ctx, child) => Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color.fromARGB(255, 0, 167, 155),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: Color.fromARGB(255, 0, 167, 155),
                                size: 18),
                            const SizedBox(width: 10),
                            Text(
                              '${_requiredBy.year}-${_requiredBy.month.toString().padLeft(2, '0')}-${_requiredBy.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Warehouses based on purpose ──────────────────
                    Obx(() {
                      final whList = widget.c.warehouses;
                      if (whList.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedPurpose == 'Material Transfer' ||
                              _selectedPurpose == 'Material Issue') ...[
                            Text('source_warehouse'.tr,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
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
                            Text('target_warehouse'.tr,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
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

                    // ── Items section ────────────────────────────────
                    Text('items_title'.tr.isNotEmpty
                        ? 'items_title'.tr
                        : 'items_label'.tr,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey)),
                    const SizedBox(height: 8),

                    // ── Item search ──────────────────────────────────
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'search_item'.tr,
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _isSearchingItems
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onChanged: _search,
                    ),

                    if (_searchResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _searchResults[index];
                            return ListTile(
                              title: Text(item['item_name'] ?? ''),
                              subtitle: Text(item['item_code'] ?? ''),
                              onTap: () => _addItem(item),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 12),

                    // ── Selected Items ───────────────────────────────
                    ..._selectedItems.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 247, 255, 253),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color.fromARGB(255, 0, 167, 155)
                                  .withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          item['item_name'] ??
                                              item['item_code'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1F2837))),
                                      Text(item['item_code'],
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                // Qty controls
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Color.fromARGB(
                                              255, 0, 167, 155)),
                                      onPressed: () => setState(() {
                                        if (item['qty'] > 1) {
                                          item['qty']--;
                                        } else {
                                          _selectedItems.removeAt(idx);
                                        }
                                      }),
                                    ),
                                    Text('${item['qty']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.add_circle_outline,
                                          color: Color.fromARGB(
                                              255, 0, 167, 155)),
                                      onPressed: () =>
                                          setState(() => item['qty']++),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red, size: 20),
                                      onPressed: () => setState(
                                          () => _selectedItems.removeAt(idx)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // ── Submit button ────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send, color: Colors.white),
                        label: Text('submit'.tr,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 0, 167, 155),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Submit Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color.fromARGB(255, 0, 167, 155),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('submit'.tr,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
