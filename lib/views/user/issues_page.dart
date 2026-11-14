import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../data/mappers/attachment_photo_mapper.dart';
import '../../domain/entities/attachment_photo.dart';
import '../../utils/error_feedback.dart';
import '../../widgets/attachment_photo_field.dart';
import '../../widgets/attachment_photo_gallery.dart';
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
    final issueType = issue['issue_type']?.toString().trim() ?? '';
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
              if (issueType.isNotEmpty) ...[
                Text(
                  'Type de ticket : $issueType',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(plainText(issue['description'])),
              const SizedBox(height: 12),
              _IssuePhotos(
                issueName: issue['name'].toString(),
                photos: mapAttachmentPhotos(r['photos']),
                photoMaxBytes: r['can_write'] == true
                    ? int.tryParse(r['photo_max_bytes']?.toString() ?? '') ?? 0
                    : 0,
              ),
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
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: TextButton(
                    onPressed: load,
                    child: const Text('Réessayer'),
                  ),
                );
              }
              final m = unwrap(snap.data!);
              if (m['error'] != null) {
                return Center(child: Text('${m['error']}'));
              }
              final rows = (m['issues'] as List? ?? []);
              if (rows.isEmpty) {
                return const Center(child: Text('Aucune Issue accessible'));
              }
              return RefreshIndicator(
                onRefresh: () async => load(),
                child: ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (_, i) {
                    final x = Map<String, dynamic>.from(rows[i] as Map);
                    final issueType = x['issue_type']?.toString().trim() ?? '';
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
                            if (issueType.isNotEmpty)
                              Text(
                                'Type de ticket : $issueType',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
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

class _IssuePhotos extends StatefulWidget {
  const _IssuePhotos({
    required this.issueName,
    required this.photos,
    required this.photoMaxBytes,
  });
  final String issueName;
  final List<AttachmentPhoto> photos;
  final int photoMaxBytes;

  @override
  State<_IssuePhotos> createState() => _IssuePhotosState();
}

class _IssuePhotosState extends State<_IssuePhotos> {
  late List<AttachmentPhoto> _photos = widget.photos;
  SelectedPhoto? _selected;
  bool _picking = false;
  bool _saving = false;
  String? _error;
  ApiClient get _api => Get.find<ApiClient>();
  String get _token => Get.find<SessionController>().token.value;

  Future<void> _save() async {
    final photo = _selected;
    if (photo == null || _saving || _picking) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = _api.unwrap(
        await _api.postMobileFile(
          'add_issue_photo',
          fields: {'token': _token, 'name': widget.issueName},
          fieldName: 'photo',
          filename: photo.name,
          bytes: photo.bytes,
        ),
      );
      final photos = mapAttachmentPhotos((result as Map)['photos']);
      if (!mounted) return;
      setState(() {
        _photos = photos;
        _selected = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = ErrorFeedback.message(error, fallbackKey: 'error_occurred');
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_photos.isEmpty && widget.photoMaxBytes <= 0) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'erp_task_attachment_photos'.tr,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (_photos.isNotEmpty) ...[
          const SizedBox(height: 8),
          AttachmentPhotoGallery(
            photos: _photos,
            loadPhoto: (fileId, {required thumbnail}) => _api.postMobileImage(
              'get_issue_photo',
              body: {
                'token': _token,
                'name': widget.issueName,
                'file_id': fileId,
                'thumbnail': thumbnail,
              },
            ),
          ),
        ],
        if (widget.photoMaxBytes > 0) ...[
          AttachmentPhotoField(
            maxBytes: widget.photoMaxBytes,
            photo: _selected,
            disabled: _saving,
            onChanged: (photo) => setState(() {
              _selected = photo;
              _error = null;
            }),
            onPickingChanged: (picking) => setState(() => _picking = picking),
          ),
          if (_selected != null)
            FilledButton.icon(
              onPressed: _saving || _picking ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file),
              label: Text('erp_issue_attach_selected_photo'.tr),
            ),
          if (_error case final String error)
            Text(error, style: const TextStyle(color: AppColors.danger)),
        ],
      ],
    );
  }
}
