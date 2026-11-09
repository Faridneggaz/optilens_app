import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';

String reportTypeLabel(String value) =>
    (value == 'Monthly Report' ? 'ar_monthly' : 'ar_weekly').tr;
String reportStatusLabel(String value) => switch (value) {
  'Open' => 'ar_action_open'.tr,
  'In Progress' => 'ar_action_working'.tr,
  'Completed' => 'ar_action_done'.tr,
  'Cancelled' => 'ar_action_cancelled'.tr,
  _ => value,
};

class ReportSection extends StatelessWidget {
  const ReportSection({
    super.key,
    required this.title,
    required this.children,
    this.onAdd,
    this.helper,
  });
  final String title;
  final List<Widget> children;
  final VoidCallback? onAdd;
  final String? helper;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.dividerMint),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            if (onAdd != null)
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: Text('ar_add'.tr),
              ),
          ],
        ),
        if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 10),
            child: Text(
              helper!,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  );
}

class ReportErrorPanel extends StatelessWidget {
  const ReportErrorPanel({super.key, required this.message, this.retry});
  final String message;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.muted),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.ink, height: 1.5),
        ),
        if (retry != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: OutlinedButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh),
              label: Text('ar_retry'.tr),
            ),
          ),
      ],
    ),
  );
}

class ReportDateField extends StatelessWidget {
  const ReportDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.allowClear = true,
  });
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool allowClear;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            foregroundColor: AppColors.body,
          ),
          icon: const Icon(Icons.calendar_today_outlined, size: 17),
          label: Text(
            '$label${value.isEmpty ? '' : ' : $value'}',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.tryParse(value) ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100, 12, 31),
            );
            if (picked != null) {
              onChanged(picked.toIso8601String().substring(0, 10));
            }
          },
        ),
      ),
      if (allowClear && value.isNotEmpty)
        IconButton(
          tooltip: 'ar_clear'.tr,
          onPressed: () => onChanged(''),
          icon: const Icon(Icons.close, size: 18),
        ),
    ],
  );
}

class ReportStatus extends StatelessWidget {
  const ReportStatus({super.key, required this.value});
  final String value;
  @override
  Widget build(BuildContext context) {
    final color = value == 'Completed'
        ? Colors.green.shade700
        : value == 'In Progress'
        ? AppColors.primaryDark
        : AppColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        reportStatusLabel(value),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
