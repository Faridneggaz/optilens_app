import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/task.dart';

class TaskVoicePlayer extends StatefulWidget {
  const TaskVoicePlayer({
    super.key,
    required this.recordingIds,
    required this.loadRecording,
    this.label,
    this.trailing,
    this.enabled = true,
    this.pendingRemovals = const {},
    this.onToggleRemoval,
  });

  final List<String> recordingIds;
  final Future<TaskVoiceAudio> Function(String) loadRecording;
  final String? label;
  final Widget? trailing;
  final bool enabled;
  final Set<String> pendingRemovals;
  final ValueChanged<String>? onToggleRemoval;

  @override
  State<TaskVoicePlayer> createState() => _TaskVoicePlayerState();
}

class _TaskVoicePlayerState extends State<TaskVoicePlayer> {
  AudioPlayer? _player;
  StreamSubscription<void>? _completion;
  Future<void>? _operation;
  File? _audioFile;
  String? _playingId;
  String? _loadingId;
  String? _errorId;

  AudioPlayer _createPlayer() {
    final player = AudioPlayer();
    _completion = player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
    return player;
  }

  void _toggle(String id) {
    if (_operation != null) return;
    setState(() {
      _loadingId = id;
      _errorId = null;
    });
    _operation = _playOrStop(id).whenComplete(() {
      _operation = null;
      if (mounted) setState(() => _loadingId = null);
    });
  }

  Future<void> _playOrStop(String id) async {
    try {
      final player = _player ??= _createPlayer();
      final stop = _playingId == id;
      if (_playingId != null) await player.stop();
      if (!mounted) return;
      _playingId = null;
      if (stop) return;

      final audio = await widget.loadRecording(id);
      if (!mounted) return;
      if (audio.bytes.isEmpty) throw StateError('Empty voice recording');
      final source = await _source(audio);
      if (!mounted) return;
      _playingId = id;
      await player.play(source);
    } catch (_) {
      _playingId = null;
      _errorId = id;
    }
  }

  Future<Source> _source(TaskVoiceAudio audio) async {
    if (kIsWeb) return BytesSource(audio.bytes, mimeType: audio.mimeType);
    await _removeAudioFile();
    final directory = await Directory.systemTemp.createTemp(
      'optilens-voice-play-',
    );
    final suffix = audio.mimeType == 'audio/ogg' ? 'ogg' : 'wav';
    final file = _audioFile = File('${directory.path}/note.$suffix');
    await file.writeAsBytes(audio.bytes);
    return DeviceFileSource(file.path, mimeType: audio.mimeType);
  }

  @override
  void dispose() {
    unawaited(_release());
    super.dispose();
  }

  Future<void> _release() async {
    await _operation;
    await _completion?.cancel();
    try {
      await _player?.dispose();
    } catch (error) {
      debugPrint('Failed to release audio player: ${error.runtimeType}');
    }
    await _removeAudioFile();
  }

  Future<void> _removeAudioFile() async {
    final file = _audioFile;
    if (file == null) return;
    _audioFile = null;
    try {
      if (await file.exists()) await file.delete();
      await file.parent.delete();
    } on FileSystemException {
      debugPrint('Could not remove the temporary voice recording.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label ?? 'erp_task_voice_title'.tr;
    return Column(
      children: [
        for (final (index, id) in widget.recordingIds.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _loadingId == id
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    tooltip:
                        (_playingId == id
                                ? 'erp_task_voice_stop_playback'
                                : 'erp_task_voice_preview')
                            .tr,
                    onPressed:
                        !widget.enabled ||
                            _loadingId != null ||
                            widget.pendingRemovals.contains(id)
                        ? null
                        : () => _toggle(id),
                    icon: Icon(
                      _playingId == id ? Icons.stop : Icons.play_arrow,
                    ),
                  ),
            title: Text(
              widget.recordingIds.length == 1 ? label : '$label ${index + 1}',
            ),
            subtitle: widget.pendingRemovals.contains(id)
                ? Text('erp_task_voice_pending_removal'.tr)
                : _errorId == id
                ? Text(
                    'erp_task_voice_playback_error'.tr,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                : null,
            trailing: _trailing(id),
          ),
      ],
    );
  }

  Widget? _trailing(String id) {
    final toggle = widget.onToggleRemoval;
    if (toggle == null) return widget.trailing;
    final pendingRemoval = widget.pendingRemovals.contains(id);
    return IconButton(
      tooltip:
          (pendingRemoval
                  ? 'erp_task_voice_undo_removal'
                  : 'erp_task_voice_remove')
              .tr,
      onPressed: widget.enabled && _loadingId == null
          ? () {
              if (_playingId == id) _toggle(id);
              toggle(id);
            }
          : null,
      icon: Icon(pendingRemoval ? Icons.undo : Icons.delete_outline),
    );
  }
}
