import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/network/api_client.dart';
import '../presentation/controllers/session_controller.dart';
import '../utils/error_feedback.dart';
import 'task/task_voice_player.dart';
import 'voice_recording_field.dart';

class IssueVoiceAttachments extends StatefulWidget {
  const IssueVoiceAttachments({
    super.key,
    required this.issueName,
    required this.recordingIds,
    required this.maxBytes,
    required this.canRemove,
  });

  final String issueName;
  final List<String> recordingIds;
  final int maxBytes;
  final bool canRemove;

  @override
  State<IssueVoiceAttachments> createState() => _IssueVoiceAttachmentsState();
}

class _IssueVoiceAttachmentsState extends State<IssueVoiceAttachments> {
  late List<String> _recordingIds = widget.recordingIds;
  final _removedIds = <String>{};
  Uint8List? _draft;
  String? _error;
  bool _saving = false;
  bool _dialogOpen = false;

  ApiClient get _api => Get.find<ApiClient>();
  Map<String, String> get _issueBody => {
    'token': Get.find<SessionController>().token.value,
    'name': widget.issueName,
  };

  Future<void> _save() async {
    if (_saving || _dialogOpen || (_draft == null && _removedIds.isEmpty)) {
      return;
    }
    final voice = _draft;
    final body = <String, dynamic>{
      ..._issueBody,
      if (_removedIds.isNotEmpty) 'removed_voice_ids': _removedIds.toList(),
    };
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final response = voice == null
          ? await _api.postMobile(
              'update_issue_voice',
              attachToken: false,
              body: body,
            )
          : await _api.postMobileAttachments(
              'update_issue_voice',
              body: body,
              photos: const [],
              voiceRecording: voice,
            );
      final result = _api.unwrap(response) as Map;
      final ids = (result['voice_ids'] as List).cast<String>();
      if (!mounted) return;
      setState(() {
        _recordingIds = ids;
        _removedIds.clear();
        _draft = null;
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (!_dialogOpen && _recordingIds.isNotEmpty)
        TaskVoicePlayer(
          key: ValueKey(_recordingIds),
          recordingIds: _recordingIds,
          loadRecording: (id) => _api.postMobileAudio(
            'get_issue_voice',
            body: {..._issueBody, 'file_id': id},
          ),
          enabled: !_saving,
          pendingRemovals: _removedIds,
          onToggleRemoval: widget.canRemove
              ? (id) => setState(() {
                  if (!_removedIds.remove(id)) _removedIds.add(id);
                })
              : null,
        ),
      VoiceRecordingField(
        maxBytes: widget.maxBytes,
        recording: _draft,
        dialogOpen: _dialogOpen,
        enabled: !_saving,
        onChanged: (voice) => setState(() => _draft = voice),
        onDialogChanged: (open) => setState(() => _dialogOpen = open),
      ),
      if (_error != null)
        Text(
          _error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      if (!_dialogOpen && (_draft != null || _removedIds.isNotEmpty))
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: Text('erp_task_save'.tr),
        ),
    ],
  );
}
