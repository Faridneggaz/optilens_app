import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme/app_colors.dart';

String translateMRStatus(String status) {
  switch (status.toLowerCase()) {
    case 'draft':
      return 'status_draft'.tr;
    case 'submitted':
      return 'status_submitted'.tr;
    case 'stopped':
      return 'status_stopped'.tr;
    case 'cancelled':
      return 'status_cancelled'.tr;
    case 'pending':
      return 'status_pending'.tr;
    case 'partially received':
      return 'status_partially_received'.tr;
    case 'partially ordered':
      return 'status_partially_ordered'.tr;
    case 'received':
      return 'status_received'.tr;
    case 'issued':
      return 'status_issued'.tr;
    case 'transferred':
      return 'status_transferred'.tr;
    case 'approved':
      return 'filter_approved'.tr;
    case 'rejected':
      return 'filter_rejected'.tr;
    case 'open':
      return 'tasks_filter_open'.tr;
    case 'closed':
      return 'tasks_filter_closed'.tr;
    default:
      return status;
  }
}

/// Backend may still return "Customer Provided" for receipts.
String normalizeMRPurpose(String purpose) {
  final p = purpose.trim();
  if (p == 'Customer Provided') return 'Material Receipt';
  return p;
}

String translateMRPurpose(String purpose) {
  switch (normalizeMRPurpose(purpose)) {
    case 'Material Transfer':
      return 'purpose_material_transfer'.tr;
    case 'Material Issue':
      return 'purpose_material_issue'.tr;
    case 'Material Receipt':
      return 'purpose_material_receipt'.tr;
    case 'Purchase':
      return 'purpose_purchase'.tr;
    case 'Manufacture':
      return 'purpose_manufacture'.tr;
    default:
      return purpose;
  }
}

const materialRequestPurposes = [
  'Material Transfer',
  'Material Issue',
];

String stockEntryTypeFromMR(String purpose) {
  switch (normalizeMRPurpose(purpose)) {
    case 'Material Issue':
      return 'Material Issue';
    case 'Material Transfer':
      return 'Material Transfer';
    case 'Material Receipt':
      return 'Material Receipt';
    default:
      return '';
  }
}

bool canCreateStockEntryFromMR({
  required int docstatus,
  required String status,
  required String purpose,
}) {
  if (stockEntryTypeFromMR(purpose).isEmpty) return false;
  if (docstatus == 2) return false;

  final s = status.trim().toLowerCase();
  if (s == 'cancelled' ||
      s == 'canceled' ||
      s == 'stopped' ||
      s == 'received' ||
      s == 'issued' ||
      s == 'transferred') {
    return false;
  }
  if (docstatus == 0 && (s == 'draft' || status == 'Draft')) return false;

  return docstatus == 1 ||
      s == 'pending' ||
      s == 'submitted' ||
      s == 'partially received' ||
      s == 'partially ordered';
}

bool needsSourceWarehouse(String purpose) {
  final p = normalizeMRPurpose(purpose);
  return p == 'Material Transfer' || p == 'Material Issue';
}

bool needsTargetWarehouse(String purpose) {
  final p = normalizeMRPurpose(purpose);
  return p == 'Material Transfer' || p == 'Material Receipt';
}

Color getMRStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'draft':
      return Colors.blueGrey;
    case 'submitted':
      return Colors.blue;
    case 'pending':
      return Colors.orange;
    case 'partially received':
    case 'partially ordered':
      return Colors.amber.shade700;
    case 'received':
    case 'issued':
      return Colors.green;
    case 'transferred':
      return AppColors.primary;
    case 'approved':
      return AppColors.primary;
    case 'rejected':
      return Colors.red;
    case 'open':
      return Colors.orange;
    case 'closed':
      return Colors.green;
    case 'stopped':
      return Colors.red;
    case 'cancelled':
      return Colors.red;
    default:
      return Colors.grey;
  }
}
