import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/manque.dart';
import '../../presentation/controllers/facture_acheteur_form_controller.dart';
import '../../presentation/controllers/language_controller.dart';
import '../../utils/manque_status_helper.dart';
import '../../widgets/header.dart';
import '../../widgets/manque/manque_widgets.dart';
import '../../widgets/material_request/mr_form_widgets.dart';
import '../../widgets/stock/document_ui.dart';

class FactureAcheteurFormPage extends StatelessWidget {
  const FactureAcheteurFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FactureAcheteurFormController>();

    return GetBuilder<LanguageController>(
      builder: (_) => Obx(() {
        if (c.isLoading.value) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final f = c.facture.value;
        if (f == null) {
          return Scaffold(
            body: Center(child: Text('manque_failed_load_facture'.tr)),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.scaffoldTint,
          body: Column(
            children: [
              AppHeader(
                title: f.name,
                customer: null,
                customerCode: '',
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: c.fetchDetail,
                  color: AppColors.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'manque_facture'.tr,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          ManqueStatusBadge(status: f.workflowState),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${'manque_commande_ref'.tr}: ${f.commandeDeManque}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      if (f.customerName.trim().isNotEmpty ||
                          f.customer.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${'manque_customer'.tr}: ${f.customerName.trim().isNotEmpty ? f.customerName : f.customer}',
                          style: const TextStyle(
                            color: AppColors.body,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (!c.isReadOnly) ...[
                        Text(
                          'manque_mode_achat'.tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _ModeChip(
                                selected: c.modeAchat.value == modeAchatPoche,
                                icon: Icons.account_balance_wallet_outlined,
                                label: 'manque_mode_poche'.tr,
                                subtitle: 'manque_mode_poche_hint'.tr,
                                onTap: () => c.setMode(modeAchatPoche),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ModeChip(
                                selected: c.modeAchat.value == modeAchatCredit,
                                icon: Icons.storefront_outlined,
                                label: 'manque_mode_credit'.tr,
                                subtitle: 'manque_mode_credit_hint'.tr,
                                onTap: () => c.setMode(modeAchatCredit),
                              ),
                            ),
                          ],
                        ),
                        if (c.modeAchat.value == modeAchatCredit) ...[
                          const SizedBox(height: 12),
                          MrLabeledField(
                            label: 'manque_supplier'.tr,
                            required: true,
                            child: DropdownButtonFormField<String>(
                              key: ValueKey(
                                  'sup-${c.suppliers.map((s) => s.name).join()}|${c.supplier.value}'),
                              initialValue: c.suppliers
                                      .any((s) => s.name == c.supplier.value)
                                  ? c.supplier.value
                                  : null,
                              hint: Text('manque_pick_supplier'.tr),
                              items: c.suppliers
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s.name,
                                      child: Text(s.displayName),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) {
                                  c.setSupplier(null);
                                  return;
                                }
                                final match = c.suppliers
                                    .where((s) => s.name == v)
                                    .toList();
                                c.setSupplier(
                                    match.isEmpty ? null : match.first);
                              },
                            ),
                          ),
                        ],
                      ] else ...[
                        MrSectionCard(
                          title: 'manque_mode_achat'.tr,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  modeAchatIcon(f.modeAchat),
                                  color: modeAchatColor(f.modeAchat),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  f.isCredit
                                      ? 'manque_mode_credit'.tr
                                      : 'manque_mode_poche'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: modeAchatColor(f.modeAchat),
                                  ),
                                ),
                              ],
                            ),
                            if (f.isCredit) ...[
                              const SizedBox(height: 8),
                              MrInfoRow(
                                label: 'manque_supplier'.tr,
                                value: f.supplierName.isNotEmpty
                                    ? f.supplierName
                                    : f.supplier,
                              ),
                            ],
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'manque_items'.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(c.lineItems.length, (i) {
                        final item = c.lineItems[i];
                        return _ItemRow(
                          item: item,
                          readOnly: c.isReadOnly,
                          onToggle: (v) => c.toggleWillBuy(i, v),
                          onRate: (v) => c.setRate(i, v),
                        );
                      }),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'manque_total'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${c.liveTotal.toStringAsFixed(2)} ${f.currency}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _BottomActions(controller: c),
            ],
          ),
        );
      }),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.selected,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.grey.shade300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon,
                  color: selected ? AppColors.primaryDark : AppColors.muted),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: selected ? AppColors.primaryDark : AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemRow extends StatefulWidget {
  const _ItemRow({
    required this.item,
    required this.readOnly,
    required this.onToggle,
    required this.onRate,
  });

  final FactureAcheteurItem item;
  final bool readOnly;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onRate;

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  late final TextEditingController _rateCtrl;

  @override
  void initState() {
    super.initState();
    _rateCtrl = TextEditingController(
      text: widget.item.rate > 0 ? widget.item.rate.toStringAsFixed(2) : '',
    );
  }

  @override
  void didUpdateWidget(covariant _ItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.item.willBuy && _rateCtrl.text.isNotEmpty) {
      _rateCtrl.clear();
    }
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final name = item.itemName.trim();
    final sameName = name.isEmpty || name == item.itemCode;
    final qty = item.qty == item.qty.roundToDouble()
        ? item.qty.toInt().toString()
        : item.qty.toString();
    final qtyLabel = item.uom.trim().isEmpty ? qty : '$qty ${item.uom}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!widget.readOnly)
                  Switch(
                    value: item.willBuy,
                    activeThumbColor: AppColors.primary,
                    onChanged: widget.onToggle,
                  )
                else
                  Icon(
                    item.willBuy ? Icons.check_circle : Icons.cancel,
                    color: item.willBuy ? Colors.green : Colors.grey,
                    size: 22,
                  ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sameName ? item.itemCode : name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        sameName ? qtyLabel : '${item.itemCode} · $qtyLabel',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.willBuy) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _rateCtrl,
                enabled: !widget.readOnly,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: 'manque_rate'.tr,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (v) {
                  final n = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                  widget.onRate(n);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.controller});

  final FactureAcheteurFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final f = controller.facture.value;
      if (f == null) return const SizedBox.shrink();

      if (f.canPay) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: DocumentPrimaryButton(
            label: 'manque_pay_buyer'.tr,
            icon: Icons.payments_outlined,
            busy: controller.isPaying.value,
            onPressed: controller.isPaying.value
                ? null
                : () async {
                    final ok = await showAppConfirmDialog(
                      context: context,
                      title: 'manque_confirm_pay'.tr,
                    );
                    if (!ok) return;
                    final r = await controller.pay();
                    if (r.isAuthHandled) return;
                    if (r.isSuccess) {
                      Get.snackbar(
                        'success'.tr,
                        'manque_paid_success'.tr,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    } else {
                      Get.snackbar(
                        'error'.tr,
                        r.error ?? 'error_occurred'.tr,
                        backgroundColor: Colors.red.shade100,
                        colorText: Colors.red.shade900,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
          ),
        );
      }

      if (controller.isReadOnly) {
        if (f.isCredit && f.isValidee) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.deepOrange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepOrange.shade200),
              ),
              child: Text(
                'manque_credit_badge'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.deepOrange.shade800,
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      }

      final ready = controller.canSubmit;
      final busy = ready
          ? controller.isSubmitting.value
          : controller.isSaving.value;
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: DocumentPrimaryButton(
            label: ready ? 'manque_validate'.tr : 'manque_save_draft'.tr,
            icon: ready ? Icons.check_circle_outline : Icons.save_outlined,
            busy: busy,
            onPressed: busy
                ? null
                : () async {
                    if (!ready) {
                      final r = await controller.saveDraft();
                      if (r.isAuthHandled) return;
                      Get.snackbar(
                        r.isSuccess ? 'success'.tr : 'error'.tr,
                        r.isSuccess
                            ? 'manque_draft_saved'.tr
                            : (r.error ?? 'error_occurred'.tr),
                        backgroundColor: r.isSuccess
                            ? Colors.green
                            : Colors.red.shade100,
                        colorText: r.isSuccess
                            ? Colors.white
                            : Colors.red.shade900,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }
                    final ok = await showAppConfirmDialog(
                      context: context,
                      title: 'manque_confirm_submit'.tr,
                    );
                    if (!ok) return;
                    final r = await controller.submit();
                    if (r.isAuthHandled) return;
                    if (r.isSuccess) {
                      final total = controller.liveTotal;
                      final msg = controller.modeAchat.value == modeAchatPoche
                          ? 'manque_submit_poche_msg'
                              .tr
                              .replaceAll('@amount', total.toStringAsFixed(2))
                          : 'manque_submit_credit_msg'.tr;
                      Get.snackbar(
                        'success'.tr,
                        msg,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    } else {
                      Get.snackbar(
                        'error'.tr,
                        r.error ?? 'error_occurred'.tr,
                        backgroundColor: Colors.red.shade100,
                        colorText: Colors.red.shade900,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
          ),
        ),
      );
    });
  }
}
