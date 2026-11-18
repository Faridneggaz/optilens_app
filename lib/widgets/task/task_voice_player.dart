import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/task.dart';
import '../../utils/voice_waveform.dart';

class TaskVoicePlayer extends StatefulWidget {
  const TaskVoicePlayer({
    super.key,
    required this.recordingIds,
    required this.loadRecording,
    this.waveforms = const {},
    this.showLabels = true,
    this.enabled = true,
    this.pendingRemovals = const {},
    this.onToggleRemoval,
  });

  final List<String> recordingIds;
  final Future<TaskVoiceAudio> Function(String) loadRecording;
  final Map<String, VoiceWaveform?> waveforms;
  final bool showLabels;
  final bool enabled;
  final Set<String> pendingRemovals;
  final ValueChanged<String>? onToggleRemoval;

  @override
  State<TaskVoicePlayer> createState() => _TaskVoicePlayerState();
}

class _TaskVoicePlayerState extends State<TaskVoicePlayer> {
  final _waveforms = <String, VoiceWaveform>{};
  final _durations = <String, Duration>{};
  AudioPlayer? _player;
  StreamSubscription<void>? _completion;
  StreamSubscription<Duration>? _positions;
  StreamSubscription<Duration>? _durationChanges;
  Future<void>? _operation;
  File? _audioFile;
  String? _loadedId;
  String? _playingId;
  String? _loadingId;
  String? _errorId;
  Duration _position = Duration.zero;

  AudioPlayer _createPlayer() {
    final player = AudioPlayer();
    _completion = player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _loadedId = null;
        _playingId = null;
        _position = Duration.zero;
      });
    });
    _positions = player.onPositionChanged.listen((position) {
      if (mounted && _loadedId != null) setState(() => _position = position);
    });
    _durationChanges = player.onDurationChanged.listen((duration) {
      final id = _loadedId;
      if (mounted && id != null) setState(() => _durations[id] = duration);
    });
    return player;
  }

  void _toggle(String id) {
    if (_operation != null) return;
    setState(() {
      _loadingId = id;
      _errorId = null;
    });
    _operation = _playOrPause(id).whenComplete(() {
      _operation = null;
      if (mounted) setState(() => _loadingId = null);
    });
  }

  Future<void> _playOrPause(String id) async {
    try {
      final player = _player ??= _createPlayer();
      if (_playingId == id) {
        await player.pause();
        _playingId = null;
        return;
      }
      if (_loadedId == id) {
        _playingId = id;
        await player.resume();
        return;
      }
      final hadSource = _loadedId != null;
      _loadedId = null;
      _playingId = null;
      _position = Duration.zero;
      if (hadSource) await player.stop();
      if (!mounted) return;

      final audio = await widget.loadRecording(id);
      if (!mounted) return;
      if (audio.bytes.isEmpty) throw StateError('Empty voice recording');
      final waveform =
          widget.waveforms[id] ?? VoiceWaveform.fromWav(audio.bytes);
      if (waveform != null) _waveforms[id] = waveform;
      final source = await _source(audio);
      if (!mounted) return;
      _loadedId = id;
      _playingId = id;
      await player.play(source);
    } catch (_) {
      _loadedId = null;
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
    await _positions?.cancel();
    await _durationChanges?.cancel();
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
  Widget build(BuildContext context) => Column(
    children: [
      for (final (index, id) in widget.recordingIds.indexed) _note(id, index),
    ],
  );

  Widget _note(String id, int index) {
    final waveform = widget.waveforms[id] ?? _waveforms[id];
    final duration = _durations[id] ?? waveform?.duration;
    final isCurrent = _loadedId == id;
    final progress =
        isCurrent && duration != null && duration.inMilliseconds > 0
        ? (_position.inMilliseconds / duration.inMilliseconds)
              .clamp(0.0, 1.0)
              .toDouble()
        : 0.0;
    final pending = widget.pendingRemovals.contains(id);
    final playing = _playingId == id;
    final removable = widget.onToggleRemoval != null;
    final title = 'erp_task_voice_title'.tr;
    final controls = Row(
      children: [
        Material(
          color: widget.showLabels ? AppColors.card : Colors.white,
          shape: const CircleBorder(),
          child: _loadingId == id
              ? const SizedBox.square(
                  dimension: 48,
                  child: Center(
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : IconButton(
                  tooltip:
                      (playing
                              ? 'erp_task_voice_pause_playback'
                              : 'erp_task_voice_preview')
                          .tr,
                  color: AppColors.primaryDark,
                  onPressed: widget.enabled && _loadingId == null && !pending
                      ? () => _toggle(id)
                      : null,
                  icon: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showLabels)
                Text(
                  widget.recordingIds.length == 1
                      ? title
                      : '$title ${index + 1}',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: VoiceWaveTrack(
                      levels: waveform?.levels ?? const [],
                      progress: progress,
                      showCursor: isCurrent,
                    ),
                  ),
                  if (duration != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      formatVoiceDuration(isCurrent ? _position : duration),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: AppColors.body,
                        fontFeatures: [FontFeature.tabularFigures()],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (removable)
          IconButton(
            tooltip:
                (pending
                        ? 'erp_task_voice_undo_removal'
                        : 'erp_task_voice_remove')
                    .tr,
            color: pending ? AppColors.primaryDark : AppColors.muted,
            onPressed: widget.enabled && _loadingId == null
                ? () {
                    if (playing) _toggle(id);
                    widget.onToggleRemoval!(id);
                  }
                : null,
            icon: Icon(pending ? Icons.undo : Icons.delete_outline_rounded),
          ),
      ],
    );
    return Card(
      margin: EdgeInsets.only(bottom: widget.showLabels ? 6 : 0),
      elevation: 0,
      color: widget.showLabels ? Colors.white : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.dividerMint),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: 10,
          end: removable ? 2 : 10,
          top: 7,
          bottom: 7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            controls,
            if (pending || _errorId == id)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 58, end: 8),
                child: Text(
                  (pending
                          ? 'erp_task_voice_pending_removal'
                          : 'erp_task_voice_playback_error')
                      .tr,
                  style: TextStyle(
                    color: pending ? AppColors.body : AppColors.danger,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class VoiceWaveTrack extends StatelessWidget {
  const VoiceWaveTrack({
    super.key,
    required this.levels,
    this.progress = 0,
    this.showCursor = false,
  });

  final List<double> levels;
  final double progress;
  final bool showCursor;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 28,
    width: double.infinity,
    child: CustomPaint(
      painter: _VoiceWavePainter(levels, progress, showCursor),
    ),
  );
}

class _VoiceWavePainter extends CustomPainter {
  const _VoiceWavePainter(this.levels, this.progress, this.showCursor);

  final List<double> levels;
  final double progress;
  final bool showCursor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 12) return;
    final paint = Paint()..strokeCap = StrokeCap.round;
    final center = size.height / 2;
    final width = size.width - 12;
    final cursor = 6 + width * progress;
    if (levels.isEmpty) {
      paint
        ..color = AppColors.menuTeal.withValues(alpha: .38)
        ..strokeWidth = 2;
      canvas.drawLine(Offset(6, center), Offset(width + 6, center), paint);
    } else {
      final step = width / levels.length;
      paint.strokeWidth = (step * .52).clamp(1.0, 3.0).toDouble();
      for (var index = 0; index < levels.length; index++) {
        final x = 6 + step * (index + .5);
        final half = 2 + levels[index] * 10;
        paint.color = showCursor && x <= cursor
            ? AppColors.primaryDark
            : AppColors.menuTeal.withValues(alpha: .38);
        canvas.drawLine(
          Offset(x, center - half),
          Offset(x, center + half),
          paint,
        );
      }
    }
    if (showCursor) {
      paint.color = AppColors.primaryDark;
      canvas.drawCircle(Offset(cursor, center), 5, paint);
    }
  }

  @override
  bool shouldRepaint(_VoiceWavePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.showCursor != showCursor ||
      !listEquals(oldDelegate.levels, levels);
}
