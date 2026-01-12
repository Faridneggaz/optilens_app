import 'package:flutter/material.dart';

Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case "paid":
    case "consolidated":
      return Colors.green;
    case "unpaid":
      return Colors.red;
    case "overdue":
      return Colors.orange;
    default:
      return Colors.black87;
  }
}
