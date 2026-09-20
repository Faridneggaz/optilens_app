import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme/app_colors.dart';

String translateMRStatus(String status) {
  switch (status.toLowerCase()) {
    case 'draft':               return 'status_draft'.tr;
    case 'submitted':           return 'status_submitted'.tr;
    case 'stopped':             return 'status_stopped'.tr;
    case 'cancelled':           return 'status_cancelled'.tr;
    case 'pending':             return 'status_pending'.tr;
    case 'partially received':  return 'status_partially_received'.tr;
    case 'received':            return 'status_received'.tr;
    case 'transferred':         return 'status_transferred'.tr;
    case 'approved':            return 'filter_approved'.tr;
    case 'rejected':            return 'filter_rejected'.tr;
    case 'open':                return 'tasks_filter_open'.tr;
    case 'closed':              return 'tasks_filter_closed'.tr;
    default:                    return status;
  }
}

String translateMRPurpose(String purpose) {
  switch (purpose) {
    case 'Material Transfer':
      return 'purpose_material_transfer'.tr;
    case 'Material Issue':
      return 'purpose_material_issue'.tr;
    case 'Purchase':
      return 'purpose_purchase'.tr;
    case 'Manufacture':
      return 'purpose_manufacture'.tr;
    case 'Customer Provided':
      return 'purpose_customer_provided'.tr;
    default:
      return purpose;
  }
}

const materialRequestPurposes = [
  'Material Transfer',
  'Material Issue',
];

String stockEntryTypeFromMR(String purpose) {
  switch (purpose) {
    case 'Material Issue':
      return 'Material Issue';
    case 'Material Transfer':
      return 'Material Transfer';
    case 'Customer Provided':
      return 'Material Receipt';
    case 'Manufacture':
      return 'Manufacture';
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
  if (status == 'Cancelled' ||
      status == 'Stopped' ||
      status == 'Received' ||
      status == 'Transferred') {
    return false;
  }
  if (docstatus == 0 && status == 'Draft') return false;
  return docstatus == 1 ||
      status == 'Pending' ||
      status == 'Partially Received' ||
      status == 'Submitted';
}

bool needsSourceWarehouse(String purpose) =>
    purpose == 'Material Transfer' || purpose == 'Material Issue';

bool needsTargetWarehouse(String purpose) =>
    purpose == 'Material Transfer';

Color getMRStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'draft':               return Colors.blueGrey;
    case 'submitted':           return Colors.blue;
    case 'pending':             return Colors.orange;
    case 'partially received':  return Colors.amber.shade700;
    case 'received':            return Colors.green;
    case 'transferred':         return AppColors.primary;
    case 'approved':            return AppColors.primary;
    case 'rejected':            return Colors.red;
    case 'open':                return Colors.orange;
    case 'closed':              return Colors.green;
    case 'stopped':             return Colors.red;
    case 'cancelled':           return Colors.red;
    default:                    return Colors.grey;
  }
}
