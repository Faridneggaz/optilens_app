import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/task.dart';
import '../../presentation/controllers/task_controller.dart';
import '../../utils/task_i18n.dart';

/// Opens a dedicated searchable user picker sheet.
/// Returns the selected [AssignableUser], or null if dismissed.
Future<AssignableUser?> showAssignableUserPicker({
  required BuildContext context,
  required TaskController controller,
  AssignableUser? selected,
  bool allowClear = false,
}) {
  return showModalBottomSheet<AssignableUser>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AssignableUserPickerSheet(
      controller: controller,
      initiallySelected: selected,
      allowClear: allowClear,
    ),
  );
}

class _AssignableUserPickerSheet extends StatefulWidget {
  const _AssignableUserPickerSheet({
    required this.controller,
    this.initiallySelected,
    this.allowClear = false,
  });

  final TaskController controller;
  final AssignableUser? initiallySelected;
  final bool allowClear;

  @override
  State<_AssignableUserPickerSheet> createState() =>
      _AssignableUserPickerSheetState();
}

class _AssignableUserPickerSheetState extends State<_AssignableUserPickerSheet> {
  final _search = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  int _seq = 0;

  List<AssignableUser> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load('');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load(String query) async {
    final seq = ++_seq;
    setState(() => _loading = true);
    final rows = await widget.controller.searchAssignableUsers(query);
    if (!mounted || seq != _seq) return;
    setState(() {
      _results = rows;
      _loading = false;
    });
  }

  void _onChanged(String raw) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 280),
      () => _load(raw.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height * 0.72;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'tasks_filter_employee'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  if (widget.allowClear)
                    TextButton(
                      onPressed: () => Navigator.pop(
                        context,
                        const AssignableUser(email: '', fullName: ''),
                      ),
                      child: Text('tasks_filter_all_employees'.tr),
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _search,
                focusNode: _focus,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: taskSearchEmployeeHint,
                  filled: true,
                  fillColor: AppColors.scaffold,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : (_search.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _search.clear();
                                _load('');
                              },
                            )
                          : null),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.4),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading && _results.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            taskNoUsersFound,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                          itemCount: _results.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey.shade200),
                          itemBuilder: (context, i) {
                            final user = _results[i];
                            final selected =
                                widget.initiallySelected?.email.toLowerCase() ==
                                    user.email.toLowerCase();
                            return ListTile(
                              selected: selected,
                              selectedTileColor:
                                  AppColors.primary.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.card,
                                child: Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              title: Text(
                                user.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              subtitle: Text(
                                user.email,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                              trailing: selected
                                  ? const Icon(Icons.check_circle,
                                      color: AppColors.primary)
                                  : null,
                              onTap: () => Navigator.pop(context, user),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
