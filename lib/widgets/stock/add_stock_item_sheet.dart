import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../material_request/mr_form_widgets.dart';

class AddStockItemResult {
  const AddStockItemResult({
    required this.itemCode,
    required this.itemName,
    required this.quantity,
  });

  final String itemCode;
  final String itemName;
  final int quantity;
}

/// Bottom sheet to pick an item + qty without fighting the parent Obx tree.
class AddStockItemSheet extends StatefulWidget {
  const AddStockItemSheet({super.key, required this.searchItems});

  final Future<List<Map<String, String>>> Function(String query) searchItems;

  @override
  State<AddStockItemSheet> createState() => _AddStockItemSheetState();
}

class _AddStockItemSheetState extends State<AddStockItemSheet> {
  final _searchCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _searchFocus = FocusNode();

  List<Map<String, String>> _results = [];
  bool _searching = false;
  String? _selectedCode;
  String? _selectedName;
  Timer? _debounce;
  int _seq = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _qtyCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String raw) {
    _debounce?.cancel();
    final q = raw.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    final seq = ++_seq;
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _searching = true);
      final rows = await widget.searchItems(q);
      if (!mounted || seq != _seq) return;
      setState(() {
        _results = rows;
        _searching = false;
      });
    });
  }

  void _select(Map<String, String> item) {
    final code = (item['item_code'] ?? '').trim();
    if (code.isEmpty) return;
    setState(() {
      _selectedCode = code;
      _selectedName = (item['item_name'] ?? code).trim();
      _searchCtrl.text = _selectedName!.isNotEmpty ? _selectedName! : code;
      _results = [];
    });
    _searchFocus.unfocus();
  }

  void _submit() {
    final code = _selectedCode;
    if (code == null || code.isEmpty) return;
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
    Navigator.of(context).pop(
      AddStockItemResult(
        itemCode: code,
        itemName: (_selectedName ?? code),
        quantity: qty < 1 ? 1 : qty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    final keyboardOpen = bottomInset > 0;
    final maxSheetHeight = media.size.height * (keyboardOpen ? 0.55 : 0.72);
    final resultsMaxHeight = keyboardOpen ? 110.0 : 180.0;
    final canAdd = _selectedCode != null && _selectedCode!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: AppColors.scaffold,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxSheetHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'add_item_dialog_title'.tr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MrItemSearchField(
                          searchController: _searchCtrl,
                          focusNode: _searchFocus,
                          isSearching: _searching,
                          onChanged: _onSearchChanged,
                        ),
                        if (_results.isNotEmpty)
                          MrItemResultsBox(
                            results: _results,
                            onAdd: _select,
                            maxHeight: resultsMaxHeight,
                          ),
                        if (_selectedCode != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: AppColors.dividerMint),
                            ),
                            child: Text(
                              '$_selectedCode'
                              '${(_selectedName != null && _selectedName != _selectedCode) ? ' — $_selectedName' : ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextField(
                          controller: _qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'quantity_label'.tr,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('btn_cancel'.tr),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: canAdd ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                          child: Text('btn_add'.tr),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
