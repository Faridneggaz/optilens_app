import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/task.dart';
import '../../presentation/controllers/task_controller.dart';
import '../../widgets/header.dart';
import '../../widgets/task/task_card.dart';
import '../../presentation/controllers/session_controller.dart';
import '../../app/routes/app_routes.dart';

class IssuesPage extends StatefulWidget {
  const IssuesPage({super.key});
  @override
  State<IssuesPage> createState() => _IssuesPageState();
}

class _IssuesPageState extends State<IssuesPage> {
  final search = TextEditingController();
  Future<Map<String, dynamic>>? request;
  String status = 'All';
  ApiClient get api => Get.find<ApiClient>();
  String get token => Get.find<SessionController>().token.value;
  String plainText(dynamic value) {
    return (value ?? '')
        .toString()
        .replaceAll(RegExp(r'<br\s*/?>|</p>|</div>'), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  Map<String, dynamic> unwrap(Map<String, dynamic> v) =>
      Map<String, dynamic>.from(api.unwrap(v) as Map);
  void load() {
    final nextRequest = api.getMobile(
      'get_issues',
      attachToken: false,
      query: {'token': token, 'search_text': search.text, 'status': status},
    );
    if (!mounted) {
      request = nextRequest;
      return;
    }
    setState(() {
      request = nextRequest;
    });
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> create() async {
    final created = await Get.toNamed(AppRoutes.issueCreate);
    if (!mounted || created is! Map) return;
    final issue = Map<String, dynamic>.from(created);
    load();
    await detail(issue);
  }

  Future<void> createTaskFromIssue(Map<String, dynamic> issue) async {
    final created = await Get.toNamed(
      '/task-create-from-issue',
      arguments: {
        'subject': issue['subject'],
        'description': plainText(issue['description']),
        'issue': issue['name'],
      },
    );
    if (created != null && mounted) {
      await Get.toNamed('/task-detail', arguments: {'name': created.name});
    }
  }

  Future<void> changeIssueStatus(
    Map<String, dynamic> item,
    List<String> statuses,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.scaffold,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final value in statuses)
              ListTile(
                title: Text(value),
                onTap: () => Navigator.pop(c, value),
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    final response = unwrap(
      await api.postMobile(
        'update_issue_status',
        attachToken: false,
        body: {'token': token, 'name': item['name'], 'status': selected},
      ),
    );
    if (!mounted) return;
    if (response['error'] != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${response['error']}')));
      return;
    }
    Navigator.of(context).pop();
    load();
  }

  Future<void> detail(Map<String, dynamic> item) async {
    final r = unwrap(
      await api.getMobile(
        'get_issue',
        attachToken: false,
        query: {'token': token, 'name': '${item['name']}'},
      ),
    );
    if (!mounted) return;
    if (r['error'] != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${r['error']}')));
      return;
    }
    final issue = Map<String, dynamic>.from(r['issue'] as Map);
    final reply = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(c).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${issue['subject']}',
                style: Theme.of(c).textTheme.titleLarge,
              ),
              Row(
                children: [
                  Expanded(child: Text('${issue['name']}')),
                  TaskStatusChip(status: '${issue['status']}'),
                  if (r['can_write'] == true)
                    IconButton(
                      tooltip: 'Changer le statut',
                      icon: const Icon(Icons.sync_alt),
                      onPressed: () => changeIssueStatus(
                        item,
                        (r['statuses'] as List? ??
                                [
                                  'Open',
                                  'Replied',
                                  'On Hold',
                                  'Resolved',
                                  'Closed',
                                ])
                            .cast<String>(),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if ((r['assignees'] as List? ?? []).isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final person in (r['assignees'] as List))
                      Chip(
                        avatar: const Icon(Icons.person, size: 16),
                        label: Text('${person['full_name']}'),
                      ),
                  ],
                ),
              ],
              Text(plainText(issue['description'])),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => createTaskFromIssue(issue),
                icon: const Icon(Icons.add_task),
                label: const Text('Créer une tâche depuis cette Issue'),
              ),
              const Divider(),
              ...((r['communications'] as List? ?? []).map((x) {
                final m = Map<String, dynamic>.from(x as Map);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${m['sender']}'),
                  subtitle: Text(plainText(m['content'])),
                );
              })),
              if (r['can_write'] == true)
                TextField(
                  controller: reply,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Répondre'),
                ),
              if (r['can_write'] == true)
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () async {
                      final out = unwrap(
                        await api.postMobile(
                          'reply_to_issue',
                          attachToken: false,
                          body: {
                            'token': token,
                            'name': issue['name'],
                            'content': reply.text,
                          },
                        ),
                      );
                      if (out['error'] == null && c.mounted) Navigator.pop(c);
                    },
                    child: const Text('Envoyer'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.scaffold,
    appBar: AppHeader(title: 'Issues', customer: null, customerCode: ''),
    floatingActionButton: FutureBuilder<Map<String, dynamic>>(
      future: request,
      builder: (_, s) {
        final m = s.data == null
            ? null
            : (() {
                try {
                  return unwrap(s.data!);
                } catch (_) {
                  return null;
                }
              })();
        return m?['can_create'] == true
            ? FloatingActionButton(
                onPressed: create,
                child: const Icon(Icons.add),
              )
            : const SizedBox.shrink();
      },
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: search,
            onSubmitted: (_) => load(),
            decoration: InputDecoration(
              hintText: 'Rechercher un ticket',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: load,
                icon: const Icon(Icons.arrow_forward),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.dividerMint),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: PopupMenuButton<String>(
            tooltip: 'Filtrer par statut',
            onSelected: (value) {
              status = value;
              load();
            },
            itemBuilder: (_) =>
                ['All', 'Open', 'Replied', 'On Hold', 'Resolved', 'Closed']
                    .map(
                      (value) => CheckedPopupMenuItem(
                        value: value,
                        checked: status == value,
                        child: Text(value == 'All' ? 'Tous' : value),
                      ),
                    )
                    .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.dividerMint),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.tune,
                    size: 18,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status == 'All' ? 'Tous les statuts' : status,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.expand_more,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: request,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              if (snap.hasError)
                return Center(
                  child: TextButton(
                    onPressed: load,
                    child: const Text('Réessayer'),
                  ),
                );
              final m = unwrap(snap.data!);
              if (m['error'] != null)
                return Center(child: Text('${m['error']}'));
              final rows = (m['issues'] as List? ?? []);
              if (rows.isEmpty)
                return const Center(child: Text('Aucune Issue accessible'));
              return RefreshIndicator(
                onRefresh: () async => load(),
                child: ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (_, i) {
                    final x = Map<String, dynamic>.from(rows[i] as Map);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.dividerMint),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.support_agent),
                        title: Text('${x['subject']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${x['name']} • ${x['opening_date']}'),
                            const SizedBox(height: 5),
                            TaskStatusChip(status: '${x['status']}'),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => detail(x),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
