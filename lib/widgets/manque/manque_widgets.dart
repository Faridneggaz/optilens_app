import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/manque.dart';
import '../../utils/manque_status_helper.dart';
import '../material_request/mr_form_widgets.dart';

class ManqueStatusBadge extends StatelessWidget {
  const ManqueStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = manqueStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.isEmpty ? '—' : status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// Champ code (Customer / Employee) avec le nom en lecture seule dessous.
class ManqueCodeField extends StatelessWidget {
  const ManqueCodeField({
    super.key,
    required this.code,
    required this.hint,
    this.linkedName = '',
    this.caption = '',
    this.onTap,
    this.enabled = true,
  });

  final String code;
  final String hint;
  final String linkedName;
  final String caption;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final name = linkedName.trim();
    final extra = caption.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: enabled ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled ? onTap : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      code.trim().isEmpty ? hint : code,
                      style: TextStyle(
                        color: code.trim().isEmpty
                            ? Colors.grey
                            : AppColors.ink,
                        fontWeight: code.trim().isEmpty
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.expand_more,
                    color: enabled ? AppColors.muted : Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (name.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              '${'manque_linked_name'.tr} $name',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
        if (extra.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              extra,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
      ],
    );
  }
}

class CommandeManqueCard extends StatelessWidget {
  const CommandeManqueCard({
    super.key,
    required this.commande,
    required this.onTap,
  });

  final CommandeDeManque commande;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        commande.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    ManqueStatusBadge(status: commande.workflowState),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (commande.transactionDate.isNotEmpty)
                      commande.transactionDate,
                    if (commande.customerName.isNotEmpty)
                      commande.customerName
                    else if (commande.customer.isNotEmpty)
                      commande.customer,
                  ].join(' · '),
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                if (commande.buyerName.isNotEmpty ||
                    commande.buyer.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    commande.buyerName.isNotEmpty
                        ? commande.buyerName
                        : commande.buyer,
                    style: const TextStyle(color: AppColors.body, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${commande.displayItemCount} article(s) · ${commande.warehouse}',
                  style: const TextStyle(color: AppColors.body, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FactureAcheteurCard extends StatelessWidget {
  const FactureAcheteurCard({
    super.key,
    required this.facture,
    required this.onTap,
  });

  final FactureAcheteur facture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final credit = facture.isCredit;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        facture.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    ManqueStatusBadge(status: facture.workflowState),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      modeAchatIcon(facture.modeAchat),
                      size: 16,
                      color: modeAchatColor(facture.modeAchat),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      credit
                          ? 'manque_mode_credit'.tr
                          : 'manque_mode_poche'.tr,
                      style: TextStyle(
                        color: modeAchatColor(facture.modeAchat),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    if (credit && facture.supplierName.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          facture.supplierName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    if (facture.commandeDeManque.isNotEmpty)
                      facture.commandeDeManque,
                    if (facture.customerName.isNotEmpty)
                      facture.customerName
                    else if (facture.buyerName.isNotEmpty)
                      facture.buyerName,
                  ].join(' · '),
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '${facture.total.toStringAsFixed(2)} ${facture.currency}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    fontSize: 15,
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

class ManqueFilterChips extends StatelessWidget {
  const ManqueFilterChips({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<String> values;
  final String selected;
  final String Function(String) labelOf;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: values.map((v) {
          final isSelected = selected == v;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(labelOf(v)),
              selected: isSelected,
              onSelected: (_) => onSelected(v),
              selectedColor: AppColors.primary.withValues(alpha: 0.18),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primaryDark : AppColors.body,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
              ),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Re-export for forms that need MrLabeledField nearby.
typedef ManqueLabeledField = MrLabeledField;
