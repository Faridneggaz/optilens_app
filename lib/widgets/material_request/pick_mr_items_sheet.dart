import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';

/// Modern item picker: search, type qty, see selected basket.
class PickMrItemsSheet extends StatefulWidget {
  const PickMrItemsSheet({
    super.key,
    required this.searchItems,
    required this.selectedItems,
    required this.onAdd,
    required this.onQtyChanged,
    required this.onRemove,
  });

  final Future<List<Map<String, String>>> Function(String query) searchItems;
  final List<Map<String, dynamic>> selectedItems;
  final void Function(Map<String, String> item, int qty) onAdd;
  final void Function(String itemCode, int qty) onQtyChanged;
  final void Function(String itemCode) onRemove;

  @override
  State<PickMrItemsSheet> createState() => _PickMrItemsSheetState();
}

class _PickMrItemsSheetState extends State<PickMrItemsSheet> {
  final _searchCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _searchFocus = FocusNode();
  final _qtyFocus = FocusNode();

  List<Map<String, String>> _results = [];
  bool _searching = false;
  Map<String, String>? _pending;
  Timer? _debounce;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _qtyCtrl.dispose();
    _searchFocus.dispose();
    _qtyFocus.dispose();
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
    setState(() => _searching = true);
    final seq = ++_seq;
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final rows = await widget.searchItems(q);
      if (!mounted || seq != _seq) return;
      setState(() {
        _results = rows;
        _searching = false;
      });
    });
  }

  void _selectPending(Map<String, String> item) {
    final code = (item['item_code'] ?? '').trim();
    if (code.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pending = {
        'item_code': code,
        'item_name': (item['item_name'] ?? code).trim(),
      };
      _qtyCtrl.text = '1';
      _results = [];
      _searchCtrl.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _qtyFocus.requestFocus();
        _qtyCtrl.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _qtyCtrl.text.length,
        );
      }
    });
  }

  void _confirmPending() {
    final pending = _pending;
    if (pending == null) return;
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
    widget.onAdd(pending, qty < 1 ? 1 : qty);
    HapticFeedback.lightImpact();
    setState(() {
      _pending = null;
      _qtyCtrl.text = '1';
    });
    _searchFocus.requestFocus();
  }

  int _qtyOf(String code) {
    for (final row in widget.selectedItems) {
      if ('${row['item_code']}' == code) {
        final q = row['qty'];
        if (q is num) return q.toInt();
        return int.tryParse('$q') ?? 0;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    final selected = widget.selectedItems;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: const Color(0xFFF3FAF8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: media.size.height * 0.92,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'search_item'.tr,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selected.isEmpty
                                  ? 'search_item_hint'.tr
                                  : '${selected.length} ${'items_title'.tr.toLowerCase()}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'search_item_hint'.tr,
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.muted),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : (_searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.cancel_rounded,
                                      color: Colors.black38),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                if (_pending != null) _buildQtyBar(),
                if (selected.isNotEmpty) _buildSelectedStrip(selected),
                Expanded(child: _buildResults()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        selected.isEmpty
                            ? 'close'.tr
                            : '${'close'.tr} · ${selected.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
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

  Widget _buildQtyBar() {
    final pending = _pending!;
    final code = pending['item_code'] ?? '';
    final name = pending['item_name'] ?? code;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.ink,
                      ),
                    ),
                    if (name.isNotEmpty && name != code)
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _pending = null),
                icon: const Icon(Icons.close, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${'quantity_label'.tr} :',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.body,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 88,
                height: 44,
                child: TextField(
                  controller: _qtyCtrl,
                  focusNode: _qtyFocus,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.scaffold,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.4),
                    ),
                  ),
                  onSubmitted: (_) => _confirmPending(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: _confirmPending,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(
                      'btn_add'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedStrip(List<Map<String, dynamic>> selected) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'items_title'.tr,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 168),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: selected.map((item) {
                final code = '${item['item_code'] ?? ''}';
                final name = '${item['item_name'] ?? ''}'.trim();
                final qty = _qtyOf(code);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              code.isNotEmpty ? code : name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            if (name.isNotEmpty && name != code)
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      _QtyField(
                        value: qty,
                        onChanged: (v) {
                          widget.onQtyChanged(code, v);
                          setState(() {});
                        },
                      ),
                      IconButton(
                        onPressed: () {
                          widget.onRemove(code);
                          setState(() {});
                        },
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_searching && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchCtrl.text.trim().isEmpty && _pending == null) {
      if (widget.selectedItems.isNotEmpty) {
        return Center(
          child: Text(
            'search_item_hint'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        );
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'search_item_hint'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }
    if (!_searching && _results.isEmpty) {
      return Center(
        child: Text(
          'no_item_found'.tr,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _results[index];
        final code = (item['item_code'] ?? '').trim();
        final name = (item['item_name'] ?? '').trim();
        final already = _qtyOf(code);
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _selectPending(item),
            child: Container(
              constraints: const BoxConstraints(minHeight: 60),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: already > 0
                      ? AppColors.primary.withValues(alpha: 0.35)
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded,
                        color: AppColors.primaryDark, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          code.isNotEmpty ? code : name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.ink,
                          ),
                        ),
                        if (name.isNotEmpty && name != code) ...[
                          const SizedBox(height: 2),
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (already > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '×$already',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.muted),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QtyField extends StatefulWidget {
  const _QtyField({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_QtyField> createState() => _QtyFieldState();
}

class _QtyFieldState extends State<_QtyField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.value}');
  }

  @override
  void didUpdateWidget(covariant _QtyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        _ctrl.text != '${widget.value}' &&
        !_ctrl.selection.isValid) {
      _ctrl.text = '${widget.value}';
    } else if (oldWidget.value != widget.value &&
        FocusManager.instance.primaryFocus?.context != context) {
      _ctrl.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 40,
      child: TextField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          filled: true,
          fillColor: AppColors.scaffold,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        onChanged: (v) {
          final n = int.tryParse(v);
          if (n != null && n >= 1) widget.onChanged(n);
        },
        onSubmitted: (v) {
          final n = int.tryParse(v) ?? 1;
          widget.onChanged(n < 1 ? 1 : n);
        },
      ),
    );
  }
}
