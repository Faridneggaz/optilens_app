import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'task/task_voice_dialog.dart';
import 'task/task_voice_player.dart';

class VoiceRecordingField extends StatelessWidget {
  const VoiceRecordingField({
    super.key,
    required this.maxBytes,
    required this.recording,
    required this.onChanged,
    required this.onDialogChanged,
    required this.dialogOpen,
    this.enabled = true,
  });

  final int maxBytes;
  final Uint8List? recording;
  final ValueChanged<Uint8List?> onChanged;
  final ValueChanged<bool> onDialogChanged;
  final bool dialogOpen;
  final bool enabled;

  Future<void> _record(BuildContext context) async {
    onDialogChanged(true);
    try {
      final voice = await showDialog<Uint8List>(
        context: context,
        barrierDismissible: false,
        builder: (_) => TaskVoiceDialog(maxBytes: maxBytes),
      );
      if (context.mounted && voice != null) onChanged(voice);
    } finally {
      if (context.mounted) onDialogChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (dialogOpen || maxBytes <= 0 || !TaskVoiceDialog.isSupported) {
      return const SizedBox.shrink();
    }
    final voice = recording;
    if (voice == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.mic_none),
        title: Text('erp_task_voice_record'.tr),
        onTap: enabled ? () => _record(context) : null,
      );
    }
    return TaskVoicePlayer(
      key: ObjectKey(voice),
      recordingIds: const ['draft'],
      loadRecording: (_) async => (bytes: voice, mimeType: 'audio/wav'),
      label: 'erp_task_voice_attached'.tr,
      enabled: enabled,
      trailing: Wrap(
        children: [
          IconButton(
            tooltip: 'erp_task_voice_replace'.tr,
            onPressed: enabled ? () => _record(context) : null,
            icon: const Icon(Icons.mic_none),
          ),
          IconButton(
            tooltip: 'erp_task_voice_remove'.tr,
            onPressed: enabled ? () => onChanged(null) : null,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
