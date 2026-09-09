import 'package:flutter/material.dart';

import '../../domain/entities/announcement.dart';
import 'app_colors.dart';

extension AnnouncementColor on Announcement {
  Color get colorValue {
    try {
      var hexColor = color.replaceAll('#', '');
      if (hexColor.length == 6) hexColor = 'FF$hexColor';
      return Color(int.parse('0x$hexColor'));
    } catch (_) {
      return AppColors.primary;
    }
  }
}
