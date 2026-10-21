import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../presentation/controllers/commande_manque_detail_controller.dart';
import '../../presentation/controllers/language_controller.dart';
import '../../widgets/header.dart';
import '../../widgets/manque/manque_widgets.dart';
import '../../widgets/material_request/mr_form_widgets.dart';
import '../../widgets/stock/document_ui.dart';

class CommandeManqueDetailPage extends StatelessWidget {
  const CommandeManqueDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CommandeManqueDetailController>();

    return GetBuilder<LanguageController>(
      builder: (_) => Obx(() {
        if (c.isLoading.value) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final cmd = c.commande.value;
        if (cmd == null) {
          return Scaffold(
            body: Center(child: Text('manque_failed_load_detail'.tr)),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.scaffoldTint,
          body: Column(
            children: [
              AppHeader(
                title: cmd.name,
                customer: null,
                customerCode: '',
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: c.fetchDetail,
                  color: AppColors.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'manque_commandes_title'.tr,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          ManqueStatusBadge(status: cmd.workflowState),
                        ],
                      ),
                      const SizedBox(height: 16),
                      MrSectionCard(
                        title: 'mr_details_section'.tr,
                        children: [
                          MrInfoRow(
                              label: 'company'.tr, value: cmd.company),
                          MrInfoRow(
                              label: 'warehouse'.tr, value: cmd.warehouse),
                          MrInfoRow(
                              label: 'task_date'.tr,
                              value: cmd.transactionDate),
                          MrInfoRow(
                            label: 'manque_buyer'.tr,
                            value: cmd.buyerName.trim().isNotEmpty
                                ? cmd.buyerName
                                : cmd.buyer,
                          ),
                          MrInfoRow(
                            label: 'manque_customer'.tr,
                            value: cmd.customer,
                          ),
                          if (cmd.customerName.trim().isNotEmpty)
                            MrInfoRow(
                              label: 'manque_customer_name'.tr,
                              value: cmd.customerName,
                            ),
                          if (cmd.factureAcheteur.isNotEmpty)
                            MrInfoRow(
                              label: 'manque_facture'.tr,
                              value: cmd.factureAcheteur,
                            ),
                        ],
                      ),
                      MrSectionCard(
                        title: 'manque_items'.tr,
                        children: [
                          for (final item in cmd.items) ...[
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                item.itemName.isNotEmpty
                                    ? item.itemName
                                    : item.itemCode,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                  '${item.itemCode} · ${item.qty} ${item.uom}'),
                            ),
                            const Divider(height: 1),
                          ],
                          if (cmd.items.isEmpty)
                            Text('manque_no_items'.tr,
                                style: const TextStyle(color: AppColors.muted)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Obx(() {
                  final busy = c.isBusy.value;
                  final draft = cmd.isDraft;
                  final canFacture = cmd.canOpenFacture;
                  return Column(
                    children: [
                      if (draft) ...[
                        DocumentPrimaryButton(
                          label: 'manque_send'.tr,
                          icon: Icons.send,
                          busy: busy,
                          onPressed: busy
                              ? null
                              : () async {
                                  final r = await c.envoyer();
                                  if (r.isAuthHandled) return;
                                  if (r.isSuccess) {
                                    Get.snackbar('success'.tr,
                                        'manque_sent_success'.tr,
                                        backgroundColor: Colors.green,
                                        colorText: Colors.white,
                                        snackPosition: SnackPosition.BOTTOM);
                                  } else {
                                    Get.snackbar('error'.tr,
                                        r.error ?? 'error_occurred'.tr,
                                        backgroundColor: Colors.red.shade100,
                                        colorText: Colors.red.shade900,
                                        snackPosition: SnackPosition.BOTTOM);
                                  }
                                },
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (canFacture)
                        DocumentPrimaryButton(
                          label: cmd.factureAcheteur.isNotEmpty
                              ? 'manque_open_facture'.tr
                              : 'manque_create_facture'.tr,
                          icon: Icons.receipt_long,
                          busy: busy,
                          onPressed: busy
                              ? null
                              : () async {
                                  final r = await c.openOrCreateFacture();
                                  if (r.isAuthHandled) return;
                                  if (!r.isSuccess) {
                                    Get.snackbar('error'.tr,
                                        r.error ?? 'error_occurred'.tr,
                                        backgroundColor: Colors.red.shade100,
                                        colorText: Colors.red.shade900,
                                        snackPosition: SnackPosition.BOTTOM);
                                  }
                                },
                        ),
                    ],
                  );
                }),
              ),
            ],
          ),
        );
      }),
    );
  }
}
