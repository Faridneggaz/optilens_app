import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/job_profile.dart';
import '../../presentation/controllers/job_profile_controller.dart';
import '../../presentation/controllers/language_controller.dart';
import '../../widgets/header.dart';
import '../../widgets/material_request/mr_form_widgets.dart';

class JobProfilePage extends StatelessWidget {
  const JobProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<JobProfileController>();

    return GetBuilder<LanguageController>(
      builder: (_) => Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Column(
          children: [
            AppHeader(
              title: 'nav_job_profile'.tr,
              customer: null,
              customerCode: '',
            ),
            Expanded(
              child: Obx(() {
                if (c.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (c.hasError && !c.hasProfile) {
                  return RefreshIndicator(
                    onRefresh: c.onRefresh,
                    color: AppColors.primary,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.2),
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 12),
                        Text(
                          c.errorMessage.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (!c.hasProfile) {
                  return RefreshIndicator(
                    onRefresh: c.onRefresh,
                    color: AppColors.primary,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.18),
                        Icon(Icons.badge_outlined,
                            size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          c.emptyMessage.value.isNotEmpty
                              ? c.emptyMessage.value
                              : 'job_profile_empty'.tr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.body,
                            fontSize: 15,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (c.headerName.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            c.headerName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                final profile = c.profile.value!;
                return RefreshIndicator(
                  onRefresh: c.onRefresh,
                  color: AppColors.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    children: [
                      _HeaderCard(
                        name: c.headerName,
                        title: c.headerTitle,
                        company: c.headerCompany,
                        department: c.employee.value?.department ?? '',
                      ),
                      if (profile.hierarchicalRelation.trim().isNotEmpty)
                        _TextSection(
                          title: 'job_hierarchical_relation'.tr,
                          body: profile.hierarchicalRelation,
                        ),
                      if (profile.functionalReporting.trim().isNotEmpty)
                        _TextSection(
                          title: 'job_functional_reporting'.tr,
                          body: profile.functionalReporting,
                        ),
                      if (profile.generalMissionText.trim().isNotEmpty)
                        _TextSection(
                          title: 'job_general_mission'.tr,
                          body: profile.generalMissionText,
                        ),
                      if (profile.authorities.isNotEmpty)
                        _ListSection(
                          title: 'job_authorities'.tr,
                          items: profile.authorities,
                        ),
                      if (profile.tasks.isNotEmpty)
                        _ListSection(
                          title: 'job_tasks'.tr,
                          items: profile.tasks,
                        ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.name,
    required this.title,
    required this.company,
    required this.department,
  });

  final String name;
  final String title;
  final String company;
  final String department;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.badge_outlined,
                color: AppColors.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : '—',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
                if (company.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    company,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (department.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    department,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextSection extends StatelessWidget {
  const _TextSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return MrSectionCard(
      title: title,
      children: [
        Text(
          body,
          style: const TextStyle(
            color: AppColors.body,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({required this.title, required this.items});

  final String title;
  final List<JobArticle> items;

  @override
  Widget build(BuildContext context) {
    return MrSectionCard(
      title: title,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${items[i].idx > 0 ? items[i].idx : i + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  items[i].description,
                  style: const TextStyle(
                    color: AppColors.body,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
