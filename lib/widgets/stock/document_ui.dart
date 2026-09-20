import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../utils/mr_status_helper.dart';

class DocumentListCard extends StatelessWidget {
  const DocumentListCard({
    super.key,
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class DocumentFilterBar extends StatelessWidget {
  const DocumentFilterBar({
    super.key,
    required this.hint,
    required this.statuses,
    required this.selectedStatus,
    required this.onSearchChanged,
    required this.onStatusChanged,
    this.searchController,
    this.statusLabel,
  });

  final String hint;
  final List<String> statuses;
  final String selectedStatus;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final TextEditingController? searchController;
  final String Function(String value)? statusLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13),
                        border: InputBorder.none,
                      ),
                      onChanged: onSearchChanged,
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
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedStatus,
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: Colors.grey),
                  items: statuses
                      .map((value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              statusLabel?.call(value) ??
                                  (value == 'All'
                                      ? 'filter_all'.tr
                                      : translateMRStatus(value)),
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onStatusChanged(v);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DocumentLoadMoreFooter extends StatelessWidget {
  const DocumentLoadMoreFooter({
    super.key,
    required this.hasMore,
    required this.isLoadingMore,
    required this.hasItems,
    required this.isSearching,
    required this.onLoadMore,
  });

  final bool hasMore;
  final bool isLoadingMore;
  final bool hasItems;
  final bool isSearching;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (isSearching) return const SizedBox.shrink();
    if (!hasMore && hasItems) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
            child: Text('all_entries_loaded'.tr,
                style: const TextStyle(color: Colors.grey))),
      );
    }
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (hasMore && hasItems) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ElevatedButton(
          onPressed: onLoadMore,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.scaffold,
            foregroundColor: Colors.teal,
            elevation: 0,
            side: const BorderSide(color: Colors.teal),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: Text('load_more'.tr,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class DocumentWarehouseBox extends StatelessWidget {
  const DocumentWarehouseBox({
    super.key,
    required this.title,
    required this.value,
    this.validated = false,
    this.enabled = false,
    this.onTap,
  });

  final String title;
  final String value;
  final bool validated;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: validated ? AppColors.primary : Colors.teal.shade200,
            width: validated ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: Colors.teal.shade700, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                  ),
                ],
              ),
            ),
            if (enabled || validated)
              Icon(
                Icons.check_circle,
                color: validated ? AppColors.primary : Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }
}

class DocumentItemLine extends StatelessWidget {
  const DocumentItemLine({
    super.key,
    required this.code,
    required this.qty,
    this.qtyWidget,
    this.trailing,
  });

  final String code;
  final String qty;
  final Widget? qtyWidget;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              code,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          qtyWidget ??
              Text(
                qty,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  fontSize: 15,
                ),
              ),
          if (trailing != null) ...[
            const SizedBox(width: 4),
            trailing!,
          ],
        ],
      ),
    );
  }
}

Future<bool> showAppConfirmDialog({
  required String title,
  String? message,
  String? confirmText,
  String? cancelText,
  Color? confirmColor,
  BuildContext? context,
}) async {
  // Avoid stacked GetX overlays that leave a dead barrier after reopen flows.
  while (Get.isDialogOpen == true) {
    Get.back();
  }

  final dialog = AlertDialog(
    backgroundColor: AppColors.scaffold,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: Text(
      title,
      style: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
        fontSize: 18,
      ),
    ),
    content: (message == null || message.trim().isEmpty)
        ? null
        : Text(
            message,
            style: const TextStyle(color: AppColors.body, fontSize: 14),
          ),
    actions: [
      TextButton(
        onPressed: () {
          final navContext = context ?? Get.overlayContext;
          if (navContext != null && Navigator.of(navContext).canPop()) {
            Navigator.of(navContext, rootNavigator: true).pop(false);
          } else {
            Get.back(result: false);
          }
        },
        child: Text(
          cancelText ?? 'cancel'.tr,
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: confirmColor ?? AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          final navContext = context ?? Get.overlayContext;
          if (navContext != null && Navigator.of(navContext).canPop()) {
            Navigator.of(navContext, rootNavigator: true).pop(true);
          } else {
            Get.back(result: true);
          }
        },
        child: Text(
          confirmText ?? 'confirm'.tr,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );

  final ctx = context ?? Get.overlayContext;
  if (ctx != null) {
    final ok = await showDialog<bool>(
      context: ctx,
      barrierDismissible: true,
      barrierColor: Colors.black26,
      useRootNavigator: true,
      builder: (_) => dialog,
    );
    return ok == true;
  }

  final ok = await Get.dialog<bool>(
    dialog,
    barrierDismissible: true,
    barrierColor: Colors.black26,
  );
  return ok == true;
}

class DocumentPrimaryButton extends StatelessWidget {
  const DocumentPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: enabled && !busy ? onPressed : null,
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon ?? Icons.check, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: Colors.grey.shade400,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
