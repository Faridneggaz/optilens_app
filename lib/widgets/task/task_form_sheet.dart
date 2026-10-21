import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/task.dart';
import '../../presentation/controllers/task_controller.dart';
import '../../utils/error_feedback.dart';
import 'pick_assignable_user_sheet.dart';
import 'task_card.dart';

Future<ErpTask?> showTaskForm({
  required BuildContext context,
  required TaskController controller,
  ErpTask? task,
}) {
  if (task != null && !task.canWrite) return Future.value();
  return showModalBottomSheet<ErpTask>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.scaffold,
    builder: (_) => TaskFormSheet(controller: controller, task: task),
  );
}

class TaskFormSheet extends StatefulWidget {
  const TaskFormSheet({super.key, required this.controller, this.task});
  final TaskController controller;
  final ErpTask? task;
  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _subject;
  late final TextEditingController _description;
  late final TextEditingController _progress;
  final _assignees = <AssignableUser>[];
  TaskOptions? _options;
  TaskProject? _project;
  String _company = '';
  String _priority = 'Medium';
  String _start = '';
  String _end = '';
  String _error = '';
  bool _loading = true;
  bool _saving = false;
  bool get _assignmentsEditable => !(widget.task?.isFinished ?? false);

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _subject = TextEditingController(text: task?.subject ?? '');
    _description = TextEditingController(text: task?.descriptionText ?? '');
    _progress = TextEditingController(text: '${task?.progress ?? 0}');
    _company = task?.company ?? '';
    _priority = task?.priority ?? 'Medium';
    _start = task?.startDate ?? '';
    _end = task?.endDate ?? '';
    if (task != null) {
      _assignees.addAll(task.assignees);
      if (task.project.isNotEmpty) {
        _project = TaskProject(name: task.project, title: task.project);
      }
    } else {
      final me = widget.controller.currentAssignableUser;
      if (me != null) _assignees.add(me);
    }
    _load();
  }

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    _progress.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final options = await widget.controller.loadOptions();
      if (!mounted) return;
      setState(() {
        _options = options;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ErrorFeedback.message(error, fallbackKey: 'failed_load_tasks');
      });
    }
  }

  Future<void> _pickUser() async {
    final picked = await showAssignableUserPicker(
      context: context,
      controller: widget.controller,
    );
    if (!mounted || picked == null || picked.email.isEmpty) return;
    if (_assignees.any((user) => user.email == picked.email)) return;
    setState(() => _assignees.add(picked));
  }

  Future<void> _pickProject() async {
    final picked = await showModalBottomSheet<TaskProject>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.scaffold,
      builder: (_) =>
          _ProjectPicker(controller: widget.controller, company: _company),
    );
    if (!mounted || picked == null) return;
    setState(() => _project = picked);
  }

  Future<void> _pickDate(bool start) async {
    final parsed = DateTime.tryParse(start ? _start : _end);
    final initial = parsed != null && parsed.year >= 2000 && parsed.year <= 2100
        ? parsed
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (!mounted || picked == null) return;
    final value =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
    setState(() {
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
    });
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    if (_start.isNotEmpty && _end.isNotEmpty && _start.compareTo(_end) > 0) {
      setState(() => _error = 'erp_task_dates_error'.tr);
      return;
    }
    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      final current = widget.task;
      final input = TaskInput(
        subject: _subject.text,
        description:
            current != null && _description.text == current.descriptionText
            ? null
            : _description.text,
        company: _company,
        project: _project?.name ?? '',
        startDate: _start,
        endDate: _end,
        priority: _priority,
        progress: double.parse(_progress.text.replaceAll(',', '.')),
        assignees: _assignees.map((user) => user.email).toList(),
        updateAssignments: _assignmentsEditable,
      );
      final saved = await widget.controller.saveTask(input, task: current);
      if (!mounted) return;
      Navigator.pop(context, saved);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = ErrorFeedback.message(error, fallbackKey: 'error_occurred');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;
    final companies = <String>{'', ...?options?.companies, _company}.toList();
    final priorities = <String>{...?options?.priorities, _priority}.toList();
    final canSave =
        !_loading &&
        options != null &&
        (widget.task?.canWrite ?? options.canCreate);
    final height =
        (MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom -
                70)
            .clamp(140.0, 800.0);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.task == null ? 'task_new'.tr : 'erp_task_edit'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Form(
                        key: _form,
                        child: Column(
                          children: [
                            if (_error.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  _error,
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),
                            if (options == null)
                              TextButton(
                                onPressed: _load,
                                child: const Icon(Icons.refresh),
                              ),
                            TextFormField(
                              controller: _subject,
                              enabled: !_saving,
                              decoration: InputDecoration(
                                labelText: '${'erp_task_subject'.tr} *',
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'erp_task_subject_required'.tr
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _description,
                              enabled: !_saving,
                              minLines: 2,
                              maxLines: 5,
                              decoration: InputDecoration(
                                labelText: 'task_description'.tr,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _company,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'erp_task_company'.tr,
                              ),
                              items: companies
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v.isEmpty ? '—' : v),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _saving
                                  ? null
                                  : (value) => setState(() {
                                      _company = value ?? '';
                                      _project = null;
                                    }),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('erp_task_project'.tr),
                              subtitle: Text(
                                _project?.title ?? 'erp_task_optional'.tr,
                              ),
                              onTap: _saving ? null : _pickProject,
                              trailing: _project == null
                                  ? const Icon(Icons.chevron_right)
                                  : IconButton(
                                      onPressed: _saving
                                          ? null
                                          : () =>
                                                setState(() => _project = null),
                                      icon: const Icon(Icons.clear),
                                    ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _dateField(
                                    'erp_task_start'.tr,
                                    _start,
                                    true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _dateField(
                                    'erp_task_end'.tr,
                                    _end,
                                    false,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _priority,
                              decoration: InputDecoration(
                                labelText: 'task_priority'.tr,
                              ),
                              items: priorities
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(taskPriorityLabel(v)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _saving
                                  ? null
                                  : (value) => setState(
                                      () => _priority = value ?? _priority,
                                    ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _progress,
                              enabled:
                                  !_saving &&
                                  !(widget.task?.isFinished ?? false),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: 'erp_task_progress'.tr,
                                suffixText: '%',
                              ),
                              validator: (value) {
                                final number = double.tryParse(
                                  (value ?? '').replaceAll(',', '.'),
                                );
                                return number == null ||
                                        !number.isFinite ||
                                        number < 0 ||
                                        number > 100
                                    ? 'erp_task_progress_error'.tr
                                    : null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                'erp_task_assignees'.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final user in _assignees)
                                    InputChip(
                                      label: Text(user.displayName),
                                      tooltip: user.email,
                                      onDeleted:
                                          _saving || !_assignmentsEditable
                                          ? null
                                          : () => setState(
                                              () => _assignees.remove(user),
                                            ),
                                    ),
                                  if (_assignmentsEditable)
                                    ActionChip(
                                      avatar: const Icon(
                                        Icons.person_add_alt,
                                        size: 18,
                                      ),
                                      label: Text('erp_task_add_assignee'.tr),
                                      onPressed: _saving ? null : _pickUser,
                                    ),
                                ],
                              ),
                            ),
                            if (!_assignmentsEditable)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text('erp_task_reopen_assignments'.tr),
                              ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: canSave && !_saving ? _save : null,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            widget.task == null
                                ? 'task_create_submit'.tr
                                : 'erp_task_save'.tr,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField(String label, String value, bool start) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: const TextStyle(fontSize: 12)),
    subtitle: Text(value.isEmpty ? '—' : value),
    onTap: _saving ? null : () => _pickDate(start),
    trailing: value.isEmpty
        ? const Icon(Icons.calendar_today_outlined, size: 18)
        : IconButton(
            icon: const Icon(Icons.clear, size: 18),
            onPressed: _saving
                ? null
                : () => setState(() {
                    if (start) {
                      _start = '';
                    } else {
                      _end = '';
                    }
                  }),
          ),
  );
}

class _ProjectPicker extends StatefulWidget {
  const _ProjectPicker({required this.controller, required this.company});
  final TaskController controller;
  final String company;
  @override
  State<_ProjectPicker> createState() => _ProjectPickerState();
}

class _ProjectPickerState extends State<_ProjectPicker> {
  final _search = TextEditingController();
  Timer? _timer;
  List<TaskProject> _projects = [];
  bool _loading = true;
  String _error = '';
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load(String value) async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final options = await widget.controller.loadOptions(
        kind: 'projects',
        search: value,
        company: widget.company,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _projects = options.projects;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = ErrorFeedback.message(error, fallbackKey: 'failed_load_tasks');
      });
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SizedBox(
      height:
          (MediaQuery.sizeOf(context).height -
              MediaQuery.viewInsetsOf(context).bottom) *
          .65,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'erp_task_project'.tr,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (v) {
                _timer?.cancel();
                _timer = Timer(
                  const Duration(milliseconds: 300),
                  () => _load(v),
                );
              },
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error.isNotEmpty)
            Padding(padding: const EdgeInsets.all(12), child: Text(_error)),
          Expanded(
            child: ListView(
              children: [
                for (final project in _projects)
                  ListTile(
                    title: Text(project.title),
                    subtitle: Text(project.name),
                    onTap: () => Navigator.pop(context, project),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
