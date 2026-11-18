import 'dart:io';
import 'dart:typed_data' show Endian;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:optilens/core/theme/app_theme.dart';
import 'package:optilens/utils/translations/app_translations.dart';
import 'package:optilens/utils/voice_waveform.dart';
import 'package:optilens/widgets/voice_recording_field.dart';

void main() {
  testWidgets(
    'resumes, validates several recordings and removes only one inline',
    (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      const channel = MethodChannel('com.llfbandit.record/messages');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final bytes = Uint8List(364)
        ..setRange(0, 4, 'RIFF'.codeUnits)
        ..setRange(8, 16, 'WAVEfmt '.codeUnits)
        ..setRange(36, 40, 'data'.codeUnits)
        ..fillRange(44, 364, 1);
      ByteData.sublistView(bytes)
        ..setUint32(4, 356, Endian.little)
        ..setUint32(16, 16, Endian.little)
        ..setUint16(20, 1, Endian.little)
        ..setUint16(22, 1, Endian.little)
        ..setUint32(24, 16000, Endian.little)
        ..setUint32(28, 32000, Endian.little)
        ..setUint16(32, 2, Endian.little)
        ..setUint16(34, 16, Endian.little)
        ..setUint32(40, 320, Endian.little);
      String? path;
      var stoppedCount = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'create':
          case 'dispose':
            return null;
          case 'hasPermission':
            return true;
          case 'start':
            path = call.arguments['path'] as String;
            File(path!).writeAsBytesSync(bytes);
            return null;
          case 'getAmplitude':
            return {'current': -25.0, 'max': -20.0};
          case 'stop':
            stoppedCount++;
            return path;
          default:
            throw MissingPluginException(call.method);
        }
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      List<Uint8List> attached = const [];
      final captureStates = <bool>[];
      await tester.pumpWidget(
        GetMaterialApp(
          locale: const Locale('fr', 'FR'),
          translations: AppTranslations(),
          theme: AppTheme.light(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => VoiceRecordingField(
                maxBytes: 1024,
                recordings: attached,
                onAttach: (voice) =>
                    setState(() => attached = [...attached, voice]),
                onRemove: (voice) => setState(
                  () => attached = attached
                      .where((item) => item != voice)
                      .toList(),
                ),
                onCaptureChanged: captureStates.add,
              ),
            ),
          ),
        ),
      );

      Future<void> pressAndWait(
        String label,
        Finder target, {
        bool hold = false,
      }) async {
        await tester.runAsync(() async {
          final tooltip = find.byTooltip(label);
          final control = tooltip.evaluate().isEmpty
              ? find.text(label)
              : tooltip;
          if (hold) {
            final gesture = await tester.startGesture(
              tester.getCenter(control),
            );
            await Future<void>.delayed(const Duration(milliseconds: 600));
            await tester.pump();
            await gesture.up();
          } else {
            await tester.tap(control);
          }
          for (var i = 0; i < 100; i++) {
            await tester.pump();
            if (target.evaluate().isNotEmpty) return;
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
        });
        expect(target, findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
        expect(tester.takeException(), isNull);
      }

      final stop = find.text('Mettre en pause');
      final preview = find.byTooltip('Joindre le vocal');
      await pressAndWait('Enregistrer un vocal', stop);
      await pressAndWait('Annuler', find.text('Enregistrer un vocal'));
      expect(attached, isEmpty);
      expect(captureStates, [true, false]);

      await pressAndWait('Enregistrer un vocal', stop);
      await pressAndWait('Mettre en pause', preview);
      expect(attached, isEmpty);
      expect(find.byTooltip('Écouter'), findsOneWidget);
      await pressAndWait('Reprendre', stop);
      await pressAndWait('Mettre en pause', preview);
      expect(stoppedCount, 3);
      expect(File(path!).existsSync(), isFalse);
      await tester.tap(preview);
      await tester.pump();
      expect(attached, hasLength(1));
      expect(
        VoiceWaveform.fromWav(attached.single)?.duration,
        const Duration(milliseconds: 20),
      );
      expect(find.text('Note vocale'), findsOneWidget);

      await pressAndWait('Ajouter un autre vocal', preview, hold: true);
      await tester.tap(preview);
      await tester.pump();
      expect(attached, hasLength(2));
      expect(find.text('Note vocale 1'), findsOneWidget);
      expect(find.text('Note vocale 2'), findsOneWidget);
      expect(find.byTooltip('Écouter'), findsNWidgets(2));

      await pressAndWait('Ajouter un autre vocal', stop);
      await pressAndWait('Envoyer le vocal', find.text('Note vocale 3'));
      expect(preview, findsNothing);
      expect(attached, hasLength(3));
      expect(attached.last, bytes);

      await tester.tap(find.byTooltip('Retirer le vocal').first);
      await tester.pump();
      expect(attached, hasLength(2));
      expect(attached.every((voice) => voice.length == bytes.length), isTrue);
      expect(captureStates, [
        true,
        false,
        true,
        false,
        true,
        false,
        true,
        false,
      ]);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );
}
