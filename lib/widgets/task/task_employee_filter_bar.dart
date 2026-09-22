import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/task.dart';
import '../../presentation/controllers/task_controller.dart';
import '../../utils/task_i18n.dart';

/// Employee filter with its own search — visually distinct from the task search.
class TaskEmployeeFilterBar extends StatefulWidget {
  const TaskEmployeeFilterBar({super.key, required this.controller});

  final TaskController controller;

  @override
  State<TaskEmployeeFilterBar> createState() => _TaskEmployeeFilterBarState();
}

class _TaskEmployeeFilterBarState extends State<TaskEmployeeFilterBar> {
  final _search = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  int _seq = 0;

  List<AssignableUser> _results = [];
  bool _loading = false;
  bool _expanded = false;
  AssignableUser? _selectedUser;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focus.hasFocus && !_expanded) {
        setState(() => _expanded = true);
        _load(_search.text.trim());
      }
    });
    final email = widget.controller.allocatedToFilter.value;
    if (email.isNotEmpty) {
      _selectedUser = AssignableUser(email: email, fullName: email);
    }
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
    setState(() {
      _expanded = true;
      _loading = true;
    });
    _debounce = Timer(
      const Duration(milliseconds: 280),
      () => _load(raw.trim()),
    );
  }

  void _select(AssignableUser user) {
    widget.controller.setAllocatedToFilter(user.email);
    setState(() {
      _selectedUser = user;
      _search.clear();
      _results = [];
      _expanded = false;
      _loading = false;
    });
    _focus.unfocus();
  }

  void _clear() {
    widget.controller.clearAllocatedToFilter();
    setState(() {
      _selectedUser = null;
      _search.clear();
      _results = [];
      _expanded = false;
    });
  }

  void _openSearch() {
    setState(() {
      _expanded = true;
      _selectedUser = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focus.requestFocus();
        _load('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!widget.controller.showEmployeeFilter) {
        return const SizedBox.shrink();
      }

      // Sync external clear
      final filterEmail = widget.controller.allocatedToFilter.value;
      if (filterEmail.isEmpty && _selectedUser != null && !_expanded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedUser = null);
        });
      }

      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'tasks_filter_employee'.tr,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 6),
            if (_selectedUser != null && !_expanded)
              _SelectedEmployeeTile(
                user: _selectedUser!,
                onChange: _openSearch,
                onClear: _clear,
              )
            else
              _SearchField(
                controller: _search,
                focusNode: _focus,
                loading: _loading,
                onChanged: _onChanged,
                onClearText: () {
                  _search.clear();
                  _load('');
                },
              ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              _ResultsPanel(
                loading: _loading,
                results: _results,
                selectedEmail: filterEmail,
                onSelect: _select,
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _SelectedEmployeeTile extends StatelessWidget {
  const _SelectedEmployeeTile({
    required this.user,
    required this.onChange,
    required this.onClear,
  });

  final AssignableUser user;
  final VoidCallback onChange;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onChange,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onChange,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text('task_change_assignee'.tr),
              ),
              IconButton(
                tooltip: 'tasks_filter_all_employees'.tr,
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.loading,
    required this.onChanged,
    required this.onClearText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final ValueChanged<String> onChanged;
  final VoidCallback onClearText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: taskSearchEmployeeHint,
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFEEF8F6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        prefixIcon: const Icon(
          Icons.person_search_outlined,
          color: AppColors.primaryDark,
          size: 22,
        ),
        suffixIcon: loading
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
            : (controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: onClearText,
                    color: AppColors.muted,
                  )
                : null),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({
    required this.loading,
    required this.results,
    required this.selectedEmail,
    required this.onSelect,
  });

  final bool loading;
  final List<AssignableUser> results;
  final String selectedEmail;
  final ValueChanged<AssignableUser> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(14),
      color: Colors.white,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.viewInsetsOf(context).bottom > 0 ? 140 : 200,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: loading && results.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
            : results.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      taskNoUsersFound,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: results.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, i) {
                      final u = results[i];
                      final selected =
                          selectedEmail.toLowerCase() == u.email.toLowerCase();
                      return ListTile(
                        dense: true,
                        selected: selected,
                        selectedTileColor:
                            AppColors.primary.withValues(alpha: 0.08),
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.card,
                          child: Text(
                            u.displayName.isNotEmpty
                                ? u.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        title: Text(
                          u.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          u.email,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(Icons.check_circle,
                                color: AppColors.primary, size: 20)
                            : null,
                        onTap: () => onSelect(u),
                      );
                    },
                  ),
      ),
    );
  }
}
