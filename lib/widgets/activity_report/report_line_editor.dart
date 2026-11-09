import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/activity_report.dart';
import '../../presentation/controllers/activity_report_form_controller.dart';
import 'report_lookup_sheet.dart';
import 'report_widgets.dart';

Future<ReportLine?> editReportLine(
  BuildContext context,
  String title, {
  ReportLine? line,
}) => showModalBottomSheet<ReportLine>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _TextLineEditor(title: title, line: line),
);

class _TextLineEditor extends StatefulWidget {
  const _TextLineEditor({required this.title, this.line});
  final String title;
  final ReportLine? line;
  @override
  State<_TextLineEditor> createState() => _TextLineEditorState();
}

class _TextLineEditorState extends State<_TextLineEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _text;
  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.line?.description ?? '');
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _EditorFrame(
    title: widget.title,
    children: [
      Form(
        key: _form,
        child: TextFormField(
          controller: _text,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(
            labelText: 'ar_description'.tr,
            alignLabelWithHint: true,
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'ar_description_required'.tr
              : null,
        ),
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(
              context,
              ReportLine(
                name: widget.line?.name ?? '',
                description: _text.text.trim(),
              ),
            );
          }
        },
        child: Text('ar_apply'.tr),
      ),
    ],
  );
}

Future<ReportAction?> editReportAction(
  BuildContext context,
  ActivityReportFormController controller, {
  ReportAction? action,
}) => showModalBottomSheet<ReportAction>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _ActionEditor(controller: controller, action: action),
);

class _ActionEditor extends StatefulWidget {
  const _ActionEditor({required this.controller, this.action});
  final ActivityReportFormController controller;
  final ReportAction? action;
  @override
  State<_ActionEditor> createState() => _ActionEditorState();
}

class _ActionEditorState extends State<_ActionEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _text;
  late String _task, _taskTitle, _employee, _employeeName, _deadline, _status;
  late bool _canReadTask;
  @override
  void initState() {
    super.initState();
    final a = widget.action;
    _text = TextEditingController(text: a?.description ?? '');
    _task = a?.taskLink ?? '';
    _taskTitle = a?.taskSubject ?? '';
    _employee = a?.responsibleEmployee ?? '';
    _employeeName = a?.responsibleName ?? '';
    _deadline = a?.deadline ?? '';
    _status = a?.status ?? 'Open';
    _canReadTask = a?.canReadTask ?? false;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickTask() async {
    final task = await showReportLookup(
      context: context,
      title: 'ar_link_task'.tr,
      loader: widget.controller.searchTasks,
    );
    if (!mounted || task == null) return;
    setState(() {
      _task = task.value;
      _taskTitle = task.label;
      _canReadTask = true;
      if (_text.text.trim().isEmpty) _text.text = task.label;
    });
  }

  Future<void> _pickEmployee() async {
    final employee = await showReportLookup(
      context: context,
      title: 'ar_responsible'.tr,
      loader: (q, offset) async {
        final result = await widget.controller.searchOptions('employees', q);
        return (items: result.items, more: false);
      },
    );
    if (!mounted || employee == null) return;
    setState(() {
      _employee = employee.value;
      _employeeName = employee.label;
    });
  }

  Widget _selection(
    String label,
    String value,
    VoidCallback select,
    VoidCallback clear,
  ) => Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: select,
          style: OutlinedButton.styleFrom(
            alignment: AlignmentDirectional.centerStart,
          ),
          child: Text(
            value.isEmpty ? label : '$label : $value',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      if (value.isNotEmpty)
        IconButton(
          tooltip: 'ar_clear'.tr,
          onPressed: clear,
          icon: const Icon(Icons.close, size: 18),
        ),
    ],
  );
  @override
  Widget build(BuildContext context) => _EditorFrame(
    title: 'ar_action'.tr,
    children: [
      Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _text,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(labelText: 'ar_description'.tr),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'ar_description_required'.tr
                  : null,
            ),
            const SizedBox(height: 14),
            _selection(
              'ar_link_task'.tr,
              _taskTitle.isEmpty ? _task : _taskTitle,
              _pickTask,
              () => setState(() {
                _task = '';
                _taskTitle = '';
                _canReadTask = false;
              }),
            ),
            _selection(
              'ar_responsible'.tr,
              _employeeName.isEmpty ? _employee : _employeeName,
              _pickEmployee,
              () => setState(() {
                _employee = '';
                _employeeName = '';
              }),
            ),
            ReportDateField(
              label: 'ar_deadline'.tr,
              value: _deadline,
              onChanged: (v) => setState(() => _deadline = v),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _status,
              isExpanded: true,
              decoration: InputDecoration(labelText: 'ar_action_status'.tr),
              items: widget.controller.options.value.statuses
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(reportStatusLabel(s)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 8),
            Text(
              'ar_action_status_help'.tr,
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(
              context,
              ReportAction(
                name: widget.action?.name ?? '',
                description: _text.text.trim(),
                taskLink: _task,
                taskSubject: _taskTitle,
                canReadTask: _canReadTask,
                responsibleEmployee: _employee,
                responsibleName: _employeeName,
                deadline: _deadline,
                status: _status,
              ),
            );
          }
        },
        child: Text('ar_apply'.tr),
      ),
    ],
  );
}

class _EditorFrame extends StatelessWidget {
  const _EditorFrame({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              (media.size.height -
                  media.viewInsets.bottom -
                  media.padding.vertical) *
              .92,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'ar_close'.tr,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
