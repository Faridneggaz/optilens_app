import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/activity_report.dart';
import '../../presentation/controllers/activity_report_form_controller.dart';
import '../../widgets/activity_report/report_line_editor.dart';
import '../../widgets/activity_report/report_lookup_sheet.dart';
import '../../widgets/activity_report/report_widgets.dart';

class ActivityReportFormPage extends StatefulWidget {
  const ActivityReportFormPage({super.key});
  @override
  State<ActivityReportFormPage> createState() => _ActivityReportFormPageState();
}

class _ActivityReportFormPageState extends State<ActivityReportFormPage> {
  bool _allowPop = false;
  ActivityReportFormController get c =>
      Get.find<ActivityReportFormController>();
  Future<bool> _confirm(String title, String message, String confirm) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('ar_keep_editing'.tr),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirm),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> _leave() async {
    if (c.saving.value) return;
    if (c.dirty.value &&
        !await _confirm(
          'ar_unsaved_title'.tr,
          'ar_unsaved_message'.tr,
          'ar_discard'.tr,
        )) {
      return;
    }
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Get.back();
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (c.draft.value.title.trim().isEmpty) {
      await c.save();
      return;
    }
    if (c.losesWeeklyAccess &&
        !await _confirm(
          'ar_access_warning_title'.tr,
          'ar_access_warning'.tr,
          'ar_save_anyway'.tr,
        )) {
      return;
    }
    if (!mounted) return;
    final result = await c.save();
    if (!mounted || result == null) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Get.back(result: result);
      Get.snackbar(
        'ar_saved'.tr,
        (result.canRead ? 'ar_saved_help' : 'ar_access_lost').tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    });
  }

  Future<void> _line(bool issues, {int? index}) async {
    final lines = issues ? c.draft.value.issues : c.draft.value.done;
    final updated = await editReportLine(
      context,
      (issues ? 'ar_issues' : 'ar_done').tr,
      line: index == null ? null : lines[index],
    );
    if (!mounted || updated == null) return;
    final result = [...lines];
    if (index == null) {
      result.add(updated);
    } else {
      result[index] = updated;
    }
    c.change(
      issues
          ? c.draft.value.copyWith(issues: result)
          : c.draft.value.copyWith(done: result),
    );
  }

  Future<void> _action({int? index}) async {
    final list = c.draft.value.actions;
    final updated = await editReportAction(
      context,
      c,
      action: index == null ? null : list[index],
    );
    if (!mounted || updated == null) return;
    final result = [...list];
    if (index == null) {
      result.add(updated);
    } else {
      result[index] = updated;
    }
    c.change(c.draft.value.copyWith(actions: result));
  }

  Future<void> _option(String kind) async {
    final option = await showReportLookup(
      context: context,
      title: (kind == 'employees' ? 'ar_participants' : 'ar_process').tr,
      loader: (query, offset) async {
        final result = await c.searchOptions(kind, query);
        return (items: result.items, more: false);
      },
    );
    if (!mounted || option == null) return;
    if (kind == 'processes') {
      c.change(c.draft.value.copyWith(process: option.value));
      return;
    }
    if (c.draft.value.participants.any((p) => p.employee == option.value)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ar_duplicate_participant'.tr)));
      return;
    }
    c.change(
      c.draft.value.copyWith(
        participants: [
          ...c.draft.value.participants,
          ReportParticipant(employee: option.value, employeeName: option.label),
        ],
      ),
    );
  }

  Widget _lineSection(bool issues) {
    final lines = issues ? c.draft.value.issues : c.draft.value.done;
    return ReportSection(
      title: (issues ? 'ar_issues' : 'ar_done').tr,
      onAdd: () => _line(issues),
      children: [
        if (lines.isEmpty)
          Text(
            'ar_add_line_help'.tr,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        for (int i = 0; i < lines.length; i++)
          _editableRow(lines[i].description, () => _line(issues, index: i), () {
            final result = [...lines]..removeAt(i);
            c.change(
              issues
                  ? c.draft.value.copyWith(issues: result)
                  : c.draft.value.copyWith(done: result),
            );
          }),
      ],
    );
  }

  Widget _editableRow(
    String text,
    VoidCallback edit,
    VoidCallback remove, {
    Widget? details,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: InkWell(
            onTap: edit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: const TextStyle(height: 1.5)),
                  if (details != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: details,
                    ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'ar_edit'.tr,
          onPressed: edit,
          icon: const Icon(Icons.edit_outlined, size: 18),
        ),
        IconButton(
          tooltip: 'ar_remove'.tr,
          onPressed: remove,
          icon: const Icon(Icons.close, size: 18),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => Obx(
    () => PopScope(
      canPop: _allowPop || (!c.dirty.value && !c.saving.value),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text((c.editing ? 'ar_edit_report' : 'ar_new').tr),
          leading: IconButton(
            tooltip: 'ar_back'.tr,
            onPressed: c.saving.value ? null : _leave,
            icon: const BackButtonIcon(),
          ),
        ),
        bottomNavigationBar: c.loading.value || !c.canEdit.value
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: FilledButton.icon(
                    onPressed: c.saving.value ? null : _save,
                    icon: c.saving.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, size: 20),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text('ar_save'.tr),
                    ),
                  ),
                ),
              ),
        body: c.loading.value
            ? const Center(child: CircularProgressIndicator())
            : !c.canEdit.value
            ? SingleChildScrollView(
                child: ReportErrorPanel(message: c.error.value, retry: c.load),
              )
            : AbsorbPointer(
                absorbing: c.saving.value,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    if (c.error.value.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.dangerSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          c.error.value,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ReportSection(
                      title: 'ar_information'.tr,
                      children: [
                        DropdownButtonFormField<String>(
                          key: ValueKey(c.draft.value.type),
                          initialValue: c.draft.value.type,
                          isExpanded: true,
                          decoration: InputDecoration(labelText: 'ar_type'.tr),
                          items: c.options.value.types
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(reportTypeLabel(t)),
                                ),
                              )
                              .toList(),
                          onChanged: (type) => c.setType(type!),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: c.titleController,
                          onChanged: (title) =>
                              c.change(c.draft.value.copyWith(title: title)),
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: '${'ar_title'.tr} *',
                          ),
                        ),
                        const SizedBox(height: 14),
                        ReportDateField(
                          label: 'ar_date'.tr,
                          value: c.draft.value.date,
                          allowClear: false,
                          onChanged: c.setDate,
                        ),
                        if (!c.draft.value.isWeekly)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _option('processes'),
                                  child: Text(
                                    c.draft.value.process.isEmpty
                                        ? 'ar_optional_process'.tr
                                        : c.draft.value.process,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              if (c.draft.value.process.isNotEmpty)
                                IconButton(
                                  tooltip: 'ar_clear'.tr,
                                  onPressed: () => c.change(
                                    c.draft.value.copyWith(process: ''),
                                  ),
                                  icon: const Icon(Icons.close, size: 18),
                                ),
                            ],
                          ),
                      ],
                    ),
                    _lineSection(false),
                    _lineSection(true),
                    ReportSection(
                      title: 'ar_actions'.tr,
                      onAdd: () => _action(),
                      helper: 'ar_assignment_help'.tr,
                      children: [
                        if (c.draft.value.actions.isEmpty)
                          Text(
                            'ar_add_action_help'.tr,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        for (int i = 0; i < c.draft.value.actions.length; i++)
                          _editableRow(
                            c.draft.value.actions[i].description,
                            () => _action(index: i),
                            () {
                              final actions = [...c.draft.value.actions]
                                ..removeAt(i);
                              c.change(
                                c.draft.value.copyWith(actions: actions),
                              );
                            },
                            details: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ReportStatus(
                                  value: c.draft.value.actions[i].status,
                                ),
                                if (c
                                    .draft
                                    .value
                                    .actions[i]
                                    .responsibleName
                                    .isNotEmpty)
                                  Text(
                                    c.draft.value.actions[i].responsibleName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (c.draft.value.isWeekly)
                      Card(
                        color: Colors.white,
                        elevation: 0,
                        child: ExpansionTile(
                          title: Text(
                            '${'ar_participants'.tr} (${c.draft.value.participants.length})',
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            12,
                            0,
                            12,
                            12,
                          ),
                          children: [
                            Text(
                              'ar_attendance_help'.tr,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                            for (
                              int i = 0;
                              i < c.draft.value.participants.length;
                              i++
                            )
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c
                                              .draft
                                              .value
                                              .participants[i]
                                              .employeeName,
                                        ),
                                        Text(
                                          (c.draft.value.participants[i].present
                                                  ? 'ar_present'
                                                  : 'ar_absent')
                                              .tr,
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value:
                                        c.draft.value.participants[i].present,
                                    onChanged: (value) {
                                      final participants = [
                                        ...c.draft.value.participants,
                                      ];
                                      participants[i] = participants[i]
                                          .withPresence(value);
                                      c.change(
                                        c.draft.value.copyWith(
                                          participants: participants,
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'ar_remove'.tr,
                                    onPressed: () {
                                      final participants = [
                                        ...c.draft.value.participants,
                                      ]..removeAt(i);
                                      c.change(
                                        c.draft.value.copyWith(
                                          participants: participants,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.close, size: 18),
                                  ),
                                ],
                              ),
                            TextButton.icon(
                              onPressed: () => _option('employees'),
                              icon: const Icon(Icons.person_add_alt, size: 18),
                              label: Text('ar_add_participant'.tr),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    ),
  );
}
