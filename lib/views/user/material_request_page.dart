import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../application/controllers/material_request_controller.dart';
import '../../domain/response/material_request_response.dart';
import '../../widgets/header.dart';
import '../../../application/controllers/language_controller.dart';
import '../../app/routes/app_routes.dart';
import '../../utils/mr_status_helper.dart';
import '../../core/services/session_service.dart';
import '../../data/repositories/employee_api.dart';
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
                        color: const Color.fromARGB(255, 247, 255, 253),
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
                        color: const Color.fromARGB(255, 247, 255, 253),
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
                    padding: const EdgeInsets.symmetric(vertical: 20),
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
            backgroundColor: const Color.fromARGB(255, 247, 255, 253),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
                  Text(translateMRStatus(req.status),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: getMRStatusColor(req.status))),
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
                            ? '${req.fromWarehouse} \\u2192 ${req.warehouse}'
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
        if (EmployeeApi.isAuthHandled(res)) {
          return;
        }
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
        if (EmployeeApi.isAuthHandled(res)) {
          return;
        }
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

    if (submitDirect) {
      setState(() => _isSubmitting = true);
    } else {
      setState(() => _isSaving = true);
    }

    final String requiredByStr =
        "${_requiredBy.year}-${_requiredBy.month.toString().padLeft(2, '0')}-${_requiredBy.day.toString().padLeft(2, '0')}";

    final itemsPayload = _selectedItems.map((e) => {
      'item_code': e['item_code'],
      'qty': e['qty'],
    }).toList();

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
      priceList:        _selectedPriceList,
      items:            itemsPayload,
    );

    if (EmployeeApi.isAuthHandled(res)) {
      if (submitDirect) {
        setState(() => _isSubmitting = false);
      } else {
        setState(() => _isSaving = false);
      }
      return;
    }
    if (res.containsKey('error')) {
      if (submitDirect) {
        setState(() => _isSubmitting = false);
      } else {
        setState(() => _isSaving = false);
      }
      Get.snackbar('Error', res['error'],
          backgroundColor: Colors.red.shade100, colorText: Colors.red);
      return;
    }

    final newDocName = res['name']?.toString() ?? res['id']?.toString() ?? res['message']?['name']?.toString();
    
    if (submitDirect && newDocName != null) {
      final submitRes = await widget.c.submitRequest(newDocName);
      setState(() => _isSubmitting = false);
      
      if (EmployeeApi.isAuthHandled(submitRes)) {
        Get.back();
        widget.c.onRefresh();
        return;
      }
      if (submitRes.containsKey('error')) {
        Get.snackbar('Warning', 'Draft created but submit failed: ${submitRes['error']}',
            backgroundColor: Colors.orange.shade100, colorText: Colors.orange.shade900);
      } else {
        Get.snackbar('Success', 'mr_submitted'.tr,
            backgroundColor: Colors.green.shade100, colorText: Colors.green);
      }
    } else {
      setState(() => _isSaving = false);
      Get.snackbar('Success', 'mr_created'.tr,
          backgroundColor: Colors.green.shade100, colorText: Colors.green);
    }
    
    Get.back(); // close sheet
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
                  padding: EdgeInsets.only(
                    left: 20, right: 20, top: 8,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  children: [
                    // â”€â”€ Company â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    if (_companies.length > 1) ...[
                      Text('select_company'.tr,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 247, 255, 253),
                                  borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedCompany,
                            items: _companies
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
                    ],

                    // â”€â”€ Purpose â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Text('purpose'.tr,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 247, 255, 253),
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

                    // â”€â”€ Required By date picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                          color: Color.fromARGB(255, 247, 255, 253),
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

                    const SizedBox(height: 16),
                    
                    // â”€â”€ Price List â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Text('price_list'.tr,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 247, 255, 253),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPriceList,
                          isExpanded: true,
                          hint: Text('select_price_list'.tr,
                              style: const TextStyle(color: Colors.grey, fontSize: 14)),
                          items: [
                            DropdownMenuItem(value: null, child: Text('none'.tr)),
                            ..._priceLists.map((p) =>
                                DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 14))))
                          ],
                          onChanged: (v) => setState(() => _selectedPriceList = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // â”€â”€ Items section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Text('items_title'.tr.isNotEmpty
                        ? 'items_title'.tr
                        : 'items_label'.tr,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey)),
                    const SizedBox(height: 8),

                    // â”€â”€ Item search â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

                    // â”€â”€ Warehouses based on purpose â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Obx(() {
                      final whList = widget.c.warehouses.toList();
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
                                color: Color.fromARGB(255, 247, 255, 253),
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
                                color: Color.fromARGB(255, 247, 255, 253),
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

                    // â”€â”€ Items section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Text('items_title'.tr.isNotEmpty
                        ? 'items_title'.tr
                        : 'items_label'.tr,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey)),
                    const SizedBox(height: 8),

                    // â”€â”€ Item search â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

                    // â”€â”€ Selected Items â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

                  ],
                ),
              ),

              // Bottom action area
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (_isSaving || _isSubmitting) ? null : () => _submit(submitDirect: false),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.teal, strokeWidth: 2))
                            : const Icon(Icons.save, color: Colors.teal),
                        label: Text('save_draft'.tr,
                            style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 16)),
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
                        onPressed: (_isSaving || _isSubmitting) ? null : () => _submit(submitDirect: true),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send, color: Colors.white),
                        label: Text('submit_direct'.tr,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 0, 167, 155),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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


