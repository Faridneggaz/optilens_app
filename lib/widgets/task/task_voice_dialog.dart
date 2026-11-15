import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:record/record.dart';

class TaskVoiceDialog extends StatefulWidget {
  const TaskVoiceDialog({super.key, required this.maxBytes});

  final int maxBytes;

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  State<TaskVoiceDialog> createState() => _TaskVoiceDialogState();
}

class _TaskVoiceDialogState extends State<TaskVoiceDialog>
    with WidgetsBindingObserver {
  static const _maxDuration = Duration(minutes: 2);

  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  final _elapsed = Stopwatch();
  late final StreamSubscription<PlayerState> _playerState;
  Directory? _directory;
  File? _file;
  Timer? _timer;
  bool _busy = false;
  bool _recording = false;
  bool _playing = false;
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _playerState = _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playing = state == PlayerState.playing);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_recording && state == AppLifecycleState.paused) {
      unawaited(_stop());
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
    await _playerState.cancel();
    try {
      await Future.wait([_player.dispose(), _recorder.dispose()]);
    } catch (error) {
      debugPrint('Failed to release audio resources: ${error.runtimeType}');
    }
    final directory = _directory;
    if (directory == null) return;
    try {
      final file = File('${directory.path}/note-vocale.wav');
      if (await file.exists()) await file.delete();
      await directory.delete();
    } on FileSystemException {
      debugPrint('Could not remove the temporary voice recording.');
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (!mounted || _busy) return;
    setState(() {
      _busy = true;
      _errorKey = null;
    });
    try {
      await action();
    } catch (_) {
      _errorKey = 'erp_task_voice_error';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() => _run(() async {
    if (!await _recorder.hasPermission()) {
      _errorKey = 'erp_task_voice_permission';
      return;
    }
    await _player.stop();
    final directory = _directory ??= await Directory.systemTemp.createTemp(
      'optilens-voice-',
    );
    final file = File('${directory.path}/note-vocale.wav');
    _file = null;
    if (await file.exists()) await file.delete();
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: file.path,
    );
    _recording = true;
    _elapsed
      ..reset()
      ..start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_elapsed.elapsed >= _maxDuration) {
        unawaited(_stop());
      } else if (mounted) {
        setState(() {});
      }
    });
  });

  Future<void> _stop() => _run(() async {
    _timer?.cancel();
    _elapsed.stop();
    try {
      final path = await _recorder.stop();
      if (path == null) throw StateError('Recording stopped without a file');
      final file = File(path);
      final size = await file.length();
      if (size <= 44) throw StateError('Recording is empty');
      if (size > widget.maxBytes) {
        _errorKey = 'erp_task_voice_too_large';
        return;
      }
      _file = file;
    } finally {
      _recording = false;
    }
  });

  Future<void> _preview() => _run(() async {
    if (_playing) {
      await _player.stop();
    } else {
      final file = _file!;
      await _player.play(DeviceFileSource(file.path, mimeType: 'audio/wav'));
    }
  });

  Future<void> _attach() => _run(() async {
    await _player.stop();
    final bytes = await _file!.readAsBytes();
    if (mounted) Navigator.pop(context, bytes);
  });

  @override
  Widget build(BuildContext context) {
    final seconds = _elapsed.elapsed.inSeconds;
    final time =
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text('erp_task_voice_title'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_recording)
              Row(
                children: [
                  const Icon(Icons.fiber_manual_record),
                  const SizedBox(width: 8),
                  Text(time),
                ],
              ),
            if (_file != null)
              TextButton.icon(
                onPressed: _busy ? null : _preview,
                icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
                label: Text(
                  (_playing
                          ? 'erp_task_voice_stop_playback'
                          : 'erp_task_voice_preview')
                      .tr,
                ),
              ),
            if (!_recording)
              OutlinedButton.icon(
                onPressed: _busy ? null : _start,
                icon: const Icon(Icons.mic_none),
                label: Text(
                  (_file == null
                          ? 'erp_task_voice_record'
                          : 'erp_task_voice_rerecord')
                      .tr,
                ),
              ),
            if (_errorKey != null)
              Text(
                _errorKey!.tr,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          if (_recording)
            FilledButton.icon(
              onPressed: _busy ? null : _stop,
              icon: const Icon(Icons.stop),
              label: Text('erp_task_voice_stop_recording'.tr),
            )
          else if (_file != null)
            FilledButton(
              onPressed: _busy ? null : _attach,
              child: Text('erp_task_voice_attach'.tr),
            ),
        ],
      ),
    );
  }
}
