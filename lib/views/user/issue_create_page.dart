import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/task.dart';
import '../../presentation/controllers/session_controller.dart';
import '../../presentation/controllers/task_controller.dart';
import '../../widgets/header.dart';
import '../../widgets/task/pick_assignable_user_sheet.dart';

class IssueCreatePage extends StatefulWidget {
  const IssueCreatePage({super.key});
  @override
  State<IssueCreatePage> createState() => _IssueCreatePageState();
}

class _IssueCreatePageState extends State<IssueCreatePage> {
  final _subject = TextEditingController();
  final _description = TextEditingController();
  final _assignees = <AssignableUser>[];
  Map<String, dynamic> _options = {};
  String? _status;
  String? _type;
  String? _priority;
  String _error = '';
  bool _loading = true;
  bool _saving = false;
  ApiClient get _api => Get.find<ApiClient>();
  String get _token => Get.find<SessionController>().token.value;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic> response) =>
      Map<String, dynamic>.from(_api.unwrap(response) as Map);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final result = _unwrap(
        await _api.getMobile(
          'get_issue_options',
          attachToken: false,
          query: {'token': _token},
        ),
      );
      if (result['error'] != null) throw Exception(result['error']);
      if (!mounted) return;
      final statuses = (result['statuses'] as List? ?? ['Open']).cast<String>();
      final types = (result['issue_types'] as List? ?? []).cast<String>();
      final priorities = (result['priorities'] as List? ?? []).cast<String>();
      setState(() {
        _options = result;
        _status = statuses.contains('Open')
            ? 'Open'
            : (statuses.isEmpty ? null : statuses.first);
        _type = types.isEmpty ? null : types.first;
        _priority = priorities.isEmpty ? null : priorities.first;
        _loading = false;
      });
    } catch (error) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = error.toString();
        });
    }
  }

  Future<void> _pickUser() async {
    final user = await showAssignableUserPicker(
      context: context,
      controller: Get.find<TaskController>(),
    );
    if (!mounted ||
        user == null ||
        user.email.isEmpty ||
        _assignees.any((u) => u.email == user.email))
      return;
    setState(() => _assignees.add(user));
  }

  Future<void> _save() async {
    if (_subject.text.trim().isEmpty) {
      setState(() => _error = 'Le sujet est obligatoire');
      return;
    }
    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      final result = _unwrap(
        await _api.postMobile(
          'create_issue',
          attachToken: false,
          body: {
            'token': _token,
            'subject': _subject.text.trim(),
            'description': _description.text,
            'issue_type': _type ?? '',
            'priority': _priority ?? '',
            'status': _status ?? 'Open',
            'assignees': _assignees.map((u) => u.email).toList(),
          },
        ),
      );
      if (result['error'] != null) throw Exception(result['error']);
      if (mounted)
        Get.back(result: Map<String, dynamic>.from(result['issue'] as Map));
    } catch (error) {
      if (mounted)
        setState(() {
          _saving = false;
          _error = error.toString();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statuses = (_options['statuses'] as List? ?? <String>[])
        .cast<String>();
    final types = (_options['issue_types'] as List? ?? <String>[])
        .cast<String>();
    final priorities = (_options['priorities'] as List? ?? <String>[])
        .cast<String>();
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          AppHeader(title: 'Nouvelle Issue', customer: null, customerCode: ''),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
                    children: [
                      if (_error.isNotEmpty)
                        Card(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              _error,
                              style: const TextStyle(color: AppColors.danger),
                            ),
                          ),
                        ),
                      _fieldCard(
                        'Informations',
                        Column(
                          children: [
                            TextField(
                              controller: _subject,
                              enabled: !_saving,
                              decoration: const InputDecoration(
                                labelText: 'Sujet *',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _description,
                              enabled: !_saving,
                              minLines: 4,
                              maxLines: 8,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                              ),
                            ),
                          ],
                        ),
                      ),
                      _fieldCard(
                        'Classification',
                        Column(
                          children: [
                            _dropdown(
                              'Type d’Issue',
                              _type,
                              types,
                              (v) => setState(() => _type = v),
                            ),
                            _dropdown(
                              'Priorité',
                              _priority,
                              priorities,
                              (v) => setState(() => _priority = v),
                            ),
                            _dropdown(
                              'Statut',
                              _status,
                              statuses,
                              (v) => setState(() => _status = v),
                            ),
                          ],
                        ),
                      ),
                      _fieldCard(
                        'Assignés',
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final user in _assignees)
                              InputChip(
                                label: Text(user.displayName),
                                tooltip: user.email,
                                onDeleted: _saving
                                    ? null
                                    : () => setState(
                                        () => _assignees.remove(user),
                                      ),
                              ),
                            ActionChip(
                              avatar: const Icon(
                                Icons.person_add_alt,
                                size: 18,
                              ),
                              label: const Text('Ajouter un utilisateur'),
                              onPressed: _saving ? null : _pickUser,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving || _loading ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Enregistrer'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldCard(String title, Widget child) => Card(
    color: Colors.white,
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.dividerMint),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    ),
  );

  Widget _dropdown(
    String label,
    String? value,
    List<String> values,
    ValueChanged<String?> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
          .toList(),
      onChanged: _saving || values.isEmpty ? null : onChanged,
    ),
  );
}
