import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:record/record.dart';

import '../core/theme/app_colors.dart';
import '../utils/voice_waveform.dart';
import 'task/task_voice_player.dart';

enum _CapturePhase { idle, starting, recording, stopping, preview }

enum _FinishAction { preview, discard, attach }

class VoiceRecordingField extends StatefulWidget {
  const VoiceRecordingField({
    super.key,
    required this.maxBytes,
    required this.recordings,
    required this.onAttach,
    required this.onRemove,
    required this.onCaptureChanged,
    this.enabled = true,
    this.canAdd = true,
  });

  static bool get isRecordingSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  final int maxBytes;
  final List<Uint8List> recordings;
  final ValueChanged<Uint8List> onAttach;
  final ValueChanged<Uint8List> onRemove;
  final ValueChanged<bool> onCaptureChanged;
  final bool enabled;
  final bool canAdd;

  @override
  State<VoiceRecordingField> createState() => _VoiceRecordingFieldState();
}

class _VoiceRecordingFieldState extends State<VoiceRecordingField>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  static const _maxDuration = Duration(minutes: 2);
  static const _barCount = 36;

  _CapturePhase _phase = _CapturePhase.idle;
  final _elapsed = Stopwatch();
  final _levels = <double>[];
  AudioRecorder? _recorder;
  Directory? _directory;
  Timer? _timer;
  Future<void>? _operation;
  Uint8List? _preview;
  VoiceWaveform? _previewWaveform;
  String? _errorKey;
  bool _sampling = false;
  bool _backgrounded = false;
  bool _holdingMic = false;
  bool _pauseAfterStart = false;

  @override
  bool get wantKeepAlive => _phase != _CapturePhase.idle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _setPhase(_CapturePhase phase) {
    if (!mounted) return;
    final wasActive = wantKeepAlive;
    setState(() => _phase = phase);
    if (wasActive != wantKeepAlive) {
      updateKeepAlive();
      widget.onCaptureChanged(wantKeepAlive);
    }
  }

  void _start({bool holdingMic = false}) {
    if (!widget.enabled ||
        !widget.canAdd ||
        (_phase != _CapturePhase.idle && _phase != _CapturePhase.preview)) {
      return;
    }
    _holdingMic = holdingMic;
    _pauseAfterStart = false;
    FocusScope.of(context).unfocus();
    _elapsed.reset();
    _levels.clear();
    _errorKey = null;
    _setPhase(_CapturePhase.starting);
    _operation = _startRecording();
  }

  void _startHoldingMic() {
    if (_phase == _CapturePhase.idle) _start(holdingMic: true);
  }

  void _releaseMic() {
    if (!_holdingMic) return;
    _holdingMic = false;
    if (_phase == _CapturePhase.starting) {
      _pauseAfterStart = true;
    } else {
      _finish();
    }
  }

  Future<void> _startRecording() async {
    try {
      final recorder = _recorder ??= AudioRecorder();
      if (!await recorder.hasPermission()) {
        _errorKey = 'erp_task_voice_permission';
        _restorePreview();
        return;
      }
      if (!mounted) return;
      final directory = _directory = await Directory.systemTemp.createTemp(
        'optilens-voice-',
      );
      if (!mounted) return;
      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: '${directory.path}/note-vocale.wav',
      );
      if (!mounted) return;
      _elapsed.start();
      _setPhase(_CapturePhase.recording);
      if (_backgrounded || _pauseAfterStart) {
        _finish();
      } else {
        _timer = Timer.periodic(const Duration(milliseconds: 150), (_) {
          if (_recordedDuration >= _maxDuration) {
            _finish();
          } else {
            setState(() {});
            unawaited(_sampleLevel(recorder));
          }
        });
      }
    } catch (_) {
      _errorKey = 'erp_task_voice_error';
      await _disposeRecorder();
      await _removeTemporaryFile();
      _restorePreview();
    }
  }

  Future<void> _sampleLevel(AudioRecorder recorder) async {
    if (_sampling) return;
    _sampling = true;
    try {
      final amplitude = await recorder.getAmplitude();
      if (!mounted || _phase != _CapturePhase.recording) return;
      final level = ((amplitude.current + 60) / 60).clamp(0.0, 1.0).toDouble();
      if (!level.isFinite) return;
      setState(() {
        if (_levels.length == _barCount) _levels.removeAt(0);
        _levels.add(level);
      });
    } catch (_) {
      // The duration remains visible if the device cannot read microphone levels.
    } finally {
      _sampling = false;
    }
  }

  void _finish([_FinishAction action = _FinishAction.preview]) {
    if (_phase != _CapturePhase.recording) return;
    _holdingMic = false;
    _timer?.cancel();
    _elapsed.stop();
    _setPhase(_CapturePhase.stopping);
    _operation = _finishRecording(action);
  }

  Future<void> _finishRecording(_FinishAction action) async {
    var attachOnSuccess = false;
    try {
      final path = await _recorder!.stop();
      if (action == _FinishAction.discard) {
        _preview = null;
        _previewWaveform = null;
        return;
      }
      if (!mounted) return;
      if (path == null) throw StateError('Recording stopped without a file');
      final file = File(path);
      final size = await file.length();
      if (size <= 44) throw StateError('Recording is empty');
      if (size > widget.maxBytes) {
        _errorKey = 'erp_task_voice_too_large';
        return;
      }
      final segment = await file.readAsBytes();
      final previous = _preview;
      final voice = previous == null
          ? segment
          : appendVoiceWav(previous, segment);
      if (voice.length > widget.maxBytes) {
        _errorKey = 'erp_task_voice_too_large';
        return;
      }
      _previewWaveform =
          VoiceWaveform.fromWav(voice) ??
          VoiceWaveform(_elapsed.elapsed, const []);
      _preview = voice;
      attachOnSuccess = action == _FinishAction.attach;
    } catch (_) {
      _errorKey = 'erp_task_voice_error';
      await _disposeRecorder();
    } finally {
      await _removeTemporaryFile();
      if (mounted && attachOnSuccess && widget.enabled && widget.canAdd) {
        _closePreview(attach: true);
      } else {
        _restorePreview();
      }
    }
  }

  void _restorePreview() =>
      _setPhase(_preview == null ? _CapturePhase.idle : _CapturePhase.preview);

  void _closePreview({required bool attach}) {
    final voice = _preview;
    if (attach && voice != null) widget.onAttach(voice);
    _preview = null;
    _previewWaveform = null;
    _errorKey = null;
    _setPhase(_CapturePhase.idle);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgrounded = true;
      _finish();
    } else if (state == AppLifecycleState.resumed) {
      _backgrounded = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    unawaited(_release());
    super.dispose();
  }

  Future<void> _release() async {
    await _operation;
    await _disposeRecorder();
    await _removeTemporaryFile();
  }

  Future<void> _disposeRecorder() async {
    final recorder = _recorder;
    _recorder = null;
    try {
      await recorder?.dispose();
    } catch (error) {
      debugPrint('Could not release the voice recorder: ${error.runtimeType}');
    }
  }

  Future<void> _removeTemporaryFile() async {
    final directory = _directory;
    if (directory == null) return;
    _directory = null;
    try {
      final file = File('${directory.path}/note-vocale.wav');
      if (await file.exists()) await file.delete();
      await directory.delete();
    } on FileSystemException {
      debugPrint('Could not remove the temporary voice recording.');
    }
  }

  Duration get _recordedDuration =>
      (_previewWaveform?.duration ?? Duration.zero) + _elapsed.elapsed;

  Widget _recordingBar() {
    final recording = _phase == _CapturePhase.recording;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.fiber_manual_record,
              size: 10,
              color: AppColors.danger,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'erp_task_voice_recording'.tr,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatVoiceDuration(_recordedDuration),
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                color: AppColors.ink,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        VoiceWaveTrack(levels: List.of(_levels)),
        Row(
          children: [
            _cancelButton(
              recording ? () => _finish(_FinishAction.discard) : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: recording
                  ? TextButton.icon(
                      onPressed: _finish,
                      icon: const Icon(Icons.pause_rounded),
                      label: Text(
                        'erp_task_voice_stop_recording'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : const Center(
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            _sendButton(
              label: 'erp_task_voice_send_recording'.tr,
              onPressed: recording && widget.enabled && widget.canAdd
                  ? () => _finish(_FinishAction.attach)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _voiceAction({
    required String label,
    required IconData icon,
    required Color background,
    required Color foreground,
    required VoidCallback? onPressed,
  }) => Material(
    color: background,
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: label,
      color: foreground,
      onPressed: onPressed,
      icon: Icon(icon),
    ),
  );

  Widget _cancelButton(VoidCallback? onPressed) => _voiceAction(
    label: 'erp_task_voice_discard'.tr,
    icon: Icons.delete_outline_rounded,
    background: AppColors.dangerSoft,
    foreground: AppColors.danger,
    onPressed: onPressed,
  );

  Widget _sendButton({
    required String label,
    required VoidCallback? onPressed,
  }) => _voiceAction(
    label: label,
    icon: Icons.send_rounded,
    background: AppColors.primaryDark,
    foreground: Colors.white,
    onPressed: onPressed,
  );

  Widget _previewPanel(Uint8List voice) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'erp_task_voice_preview_title'.tr,
        style: const TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      TaskVoicePlayer(
        key: ObjectKey(voice),
        recordingIds: const ['preview'],
        loadRecording: (_) async => (bytes: voice, mimeType: 'audio/wav'),
        waveforms: {'preview': _previewWaveform},
        showLabels: false,
        enabled: widget.enabled,
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          _cancelButton(
            widget.enabled ? () => _closePreview(attach: false) : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextButton.icon(
              onPressed:
                  widget.enabled &&
                      (_previewWaveform?.duration ?? Duration.zero) <
                          _maxDuration
                  ? _start
                  : null,
              icon: const Icon(Icons.mic_none_rounded, size: 20),
              label: Text(
                'erp_task_voice_resume'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.card,
                foregroundColor: AppColors.primaryDark,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _sendButton(
            label: 'erp_task_voice_attach'.tr,
            onPressed: widget.enabled && widget.canAdd
                ? () => _closePreview(attach: true)
                : null,
          ),
        ],
      ),
    ],
  );

  Widget _draftList() {
    final recordings = widget.recordings;
    final ids = List.generate(recordings.length, (index) => '$index');
    Uint8List findRecording(String id) => recordings[int.parse(id)];
    return TaskVoicePlayer(
      key: ObjectKey(recordings),
      recordingIds: ids,
      loadRecording: (id) async =>
          (bytes: findRecording(id), mimeType: 'audio/wav'),
      waveforms: {
        for (final id in ids) id: VoiceWaveform.fromWav(findRecording(id)),
      },
      enabled: widget.enabled,
      onToggleRemoval: (id) => widget.onRemove(findRecording(id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final canRecord =
        widget.maxBytes > 0 && VoiceRecordingField.isRecordingSupported;
    final idle = _phase == _CapturePhase.idle;
    final recordings = widget.recordings;
    if (!canRecord && recordings.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (idle && recordings.isNotEmpty) ...[
            Text(
              'erp_task_voice_pending_upload'.tr,
              style: const TextStyle(
                color: AppColors.body,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            _draftList(),
          ],
          if (canRecord)
            GestureDetector(
              onLongPress: _startHoldingMic,
              onLongPressEnd: (_) => _releaseMic(),
              child: idle
                  ? OutlinedButton.icon(
                      onPressed: widget.enabled && widget.canAdd
                          ? _start
                          : null,
                      icon: const Icon(Icons.mic_none_rounded, size: 20),
                      label: Text(
                        (recordings.isEmpty
                                ? 'erp_task_voice_record'
                                : 'erp_task_voice_record_more')
                            .tr,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: const BorderSide(color: AppColors.dividerMint),
                      ),
                    )
                  : Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.dividerMint),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _phase == _CapturePhase.preview
                            ? _previewPanel(_preview!)
                            : _recordingBar(),
                      ),
                    ),
            ),
          if (_errorKey != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _errorKey!.tr,
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
        ],
      ),
    );
  }
}
