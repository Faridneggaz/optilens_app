import 'package:flutter/material.dart';
import 'package:get/get.dart';

String translateMRStatus(String status) {
  switch (status) {
    case 'Draft':               return 'status_draft'.tr;
    case 'Submitted':           return 'status_submitted'.tr;
    case 'Stopped':             return 'status_stopped'.tr;
    case 'Cancelled':           return 'status_cancelled'.tr;
    case 'Pending':             return 'status_pending'.tr;
    case 'Partially Received':  return 'status_partially_received'.tr;
    case 'Received':            return 'status_received'.tr;
    case 'Transferred':         return 'status_transferred'.tr;
    default:                    return status;
  }
}

Color getMRStatusColor(String status) {
  switch (status) {
    case 'Draft':               return Colors.blueGrey;
    case 'Submitted':           return Colors.blue;
    case 'Pending':             return Colors.orange;
    case 'Partially Received':  return Colors.amber.shade700;
    case 'Received':            return Colors.green;
    case 'Transferred':         return const Color.fromARGB(255, 0, 167, 155);
    case 'Stopped':             return Colors.red;
    case 'Cancelled':           return Colors.red;
    default:                    return Colors.grey;
  }
}
