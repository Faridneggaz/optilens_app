import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/task.dart';
import '../../presentation/controllers/task_controller.dart';
import '../material_request/mr_form_widgets.dart';
import '../stock/document_ui.dart';
import '../../utils/task_i18n.dart';
import 'pick_assignable_user_sheet.dart';

class CreateTodoSheet extends StatefulWidget {
  const CreateTodoSheet({super.key, required this.controller});

  final TaskController controller;

  @override
  State<CreateTodoSheet> createState() => _CreateTodoSheetState();
}

class _CreateTodoSheetState extends State<CreateTodoSheet> {
  final _description = TextEditingController();

  DateTime _date = DateTime.now();
  String _priority = 'Medium';
  bool _saving = false;
  String? _error;
  AssignableUser? _selectedUser;

  static const _priorities = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    _selectedUser = widget.controller.currentAssignableUser;
    _enrichDefaultUser();
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _enrichDefaultUser() async {
    final current = _selectedUser;
    if (current == null) return;
    final rows = await widget.controller.searchAssignableUsers('');
    if (!mounted) return;
    for (final u in rows) {
      if (u.email.toLowerCase() == current.email.toLowerCase()) {
        setState(() => _selectedUser = u);
        return;
      }
    }
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickAssignee() async {
    final picked = await showAssignableUserPicker(
      context: context,
      controller: widget.controller,
      selected: _selectedUser,
    );
    if (picked == null || !mounted) return;
    if (picked.email.trim().isEmpty) return;
    setState(() {
      _selectedUser = picked;
      _error = null;
    });
  }

  Future<void> _submit() async {
    final description = _description.text.trim();
    final selected = _selectedUser;
    if (description.isEmpty) {
      setState(() => _error = 'task_description_required'.tr);
      return;
    }
    if (selected == null || selected.email.trim().isEmpty) {
      setState(() => _error = 'task_allocated_required'.tr);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await widget.controller.createTodo(
      description: description,
      allocatedTo: selected.email.trim(),
      date: _fmt(_date),
      priority: _priority,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.isAuthHandled) return;
    if (result.isSuccess) {
      Navigator.of(context).pop(true);
      Get.snackbar(
        'success'.tr,
        'task_created_success'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    setState(() {
      _error = result.error ?? 'task_create_denied'.tr;
    });
  }

  InputDecoration _fieldDecoration({String? hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.scaffold,
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final user = _selectedUser;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'task_new'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 16),
                MrLabeledField(
                  label: 'task_description'.tr,
                  required: true,
                  child: TextField(
                    controller: _description,
                    maxLines: 4,
                    minLines: 3,
                    textInputAction: TextInputAction.newline,
                    decoration: _fieldDecoration(
                      hint: 'task_description_hint'.tr,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                MrLabeledField(
                  label: 'task_allocated_to'.tr,
                  required: true,
                  child: Material(
                    color: AppColors.scaffold,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _pickAssignee,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline,
                                color: AppColors.primaryDark),
                            const SizedBox(width: 10),
                            Expanded(
                              child: user == null
                                  ? Text(
                                      taskPickEmployee,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.displayName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.ink,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          user.email,
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            const Icon(Icons.keyboard_arrow_down,
                                color: AppColors.muted),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                MrLabeledField(
                  label: 'task_date'.tr,
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: _fieldDecoration(
                        suffix: const Icon(Icons.event, size: 20),
                      ),
                      child: Text(
                        _fmt(_date),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                MrLabeledField(
                  label: 'task_priority'.tr,
                  child: DropdownButtonFormField<String>(
                    value: _priority,
                    items: _priorities
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _priority = v);
                    },
                    decoration: _fieldDecoration(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                DocumentPrimaryButton(
                  label: 'task_create_submit'.tr,
                  icon: Icons.add_task,
                  busy: _saving,
                  onPressed: _saving ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
