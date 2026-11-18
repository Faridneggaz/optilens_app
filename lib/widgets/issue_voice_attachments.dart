import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/network/api_client.dart';
import '../domain/entities/attachment_photo.dart';
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
    required this.maxBatchBytes,
    required this.canRemove,
  });

  final String issueName;
  final List<String> recordingIds;
  final int maxBytes;
  final int maxBatchBytes;
  final bool canRemove;

  @override
  State<IssueVoiceAttachments> createState() => _IssueVoiceAttachmentsState();
}

class _IssueVoiceAttachmentsState extends State<IssueVoiceAttachments> {
  late List<String> _recordingIds = widget.recordingIds;
  final _removedIds = <String>{};
  List<Uint8List> _drafts = const [];
  String? _error;
  bool _saving = false;
  bool _voiceCaptureActive = false;

  ApiClient get _api => Get.find<ApiClient>();
  Map<String, String> get _issueBody => {
    'token': Get.find<SessionController>().token.value,
    'name': widget.issueName,
  };

  Future<void> _save() async {
    if (_saving ||
        _voiceCaptureActive ||
        (_drafts.isEmpty && _removedIds.isEmpty)) {
      return;
    }
    final voices = _drafts;
    if (voices.isNotEmpty &&
        attachmentUploadBytes(const [], voices) > widget.maxBatchBytes) {
      setState(() => _error = 'erp_task_voice_batch_limit'.tr);
      return;
    }
    final body = <String, dynamic>{
      ..._issueBody,
      if (_removedIds.isNotEmpty) 'removed_voice_ids': _removedIds.toList(),
    };
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final response = voices.isEmpty
          ? await _api.postMobile(
              'update_issue_voice',
              attachToken: false,
              body: body,
            )
          : await _api.postMobileAttachments(
              'update_issue_voice',
              body: body,
              photos: const [],
              voiceRecordings: voices,
            );
      final result = _api.unwrap(response) as Map;
      final ids = (result['voice_ids'] as List).cast<String>();
      if (!mounted) return;
      setState(() {
        _recordingIds = ids;
        _removedIds.clear();
        _drafts = const [];
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
    if (_recordingIds.isEmpty &&
        (widget.maxBytes <= 0 || !VoiceRecordingField.isRecordingSupported)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'erp_task_attachment_voice'.tr,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (!_voiceCaptureActive && _recordingIds.isNotEmpty)
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
            recordings: _drafts,
            enabled: !_saving,
            onAttach: (voice) => setState(() => _drafts = [..._drafts, voice]),
            onRemove: (voice) => setState(
              () => _drafts = _drafts.where((item) => item != voice).toList(),
            ),
            onCaptureChanged: (active) =>
                setState(() => _voiceCaptureActive = active),
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (!_voiceCaptureActive &&
              (_drafts.isNotEmpty || _removedIds.isNotEmpty))
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text('erp_task_save'.tr),
            ),
        ],
      ),
    );
  }
}
