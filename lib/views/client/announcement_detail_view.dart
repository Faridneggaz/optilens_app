import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/announcement_color.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/announcement.dart';
import '../../../presentation/controllers/language_controller.dart';

class AnnouncementDetailPage extends StatelessWidget {
  const AnnouncementDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final announcement = Get.arguments as Announcement;

    return GetBuilder<LanguageController>(
      builder: (_) => Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          title: Text('announcement_detail_title'.tr),
          elevation: 0,
          backgroundColor: AppColors.scaffold,
          foregroundColor: AppColors.ink,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (announcement.image != null && announcement.image!.isNotEmpty)
                Image.network(
                  announcement.image!,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: announcement.colorValue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        announcement.type.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 15),

                    Text(
                      announcement.title,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      '${'published_on'.tr}${announcement.postedTime}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                    const Divider(height: 40, thickness: 1),

                    Text(
                      announcement.subtitle,
                      style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: AppColors.body),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
