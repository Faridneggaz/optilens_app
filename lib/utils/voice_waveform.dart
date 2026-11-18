import 'dart:math' as math;
import 'dart:typed_data';

class VoiceWaveform {
  const VoiceWaveform(this.duration, this.levels);

  final Duration duration;
  final List<double> levels;

  static VoiceWaveform? fromWav(Uint8List bytes) {
    final wav = _PcmWave.read(bytes);
    if (wav == null) return null;

    const bars = 36;
    final data = ByteData.sublistView(bytes);
    final frames = wav.length ~/ wav.frameBytes;
    final levels = List.generate(bars, (index) {
      final first = index * frames ~/ bars;
      final end = (index + 1) * frames ~/ bars;
      final step = math.max(1, (end - first) ~/ 64);
      var peak = 0;
      for (var frame = first; frame < end; frame += step) {
        final offset = wav.offset + frame * wav.frameBytes;
        for (var channel = 0; channel < wav.channels; channel++) {
          final sample = data.getInt16(offset + channel * 2, Endian.little);
          peak = math.max(peak, sample.abs());
        }
      }
      return math.sqrt(peak / 32768);
    });
    final duration = Duration(
      microseconds: frames * Duration.microsecondsPerSecond ~/ wav.sampleRate,
    );
    return VoiceWaveform(duration, levels);
  }
}

String formatVoiceDuration(Duration duration) {
  final seconds = duration.inSeconds;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

Uint8List appendVoiceWav(Uint8List first, Uint8List second) {
  final a = _PcmWave.read(first);
  final b = _PcmWave.read(second);
  if (a == null ||
      b == null ||
      a.sampleRate != b.sampleRate ||
      a.channels != b.channels) {
    throw const FormatException('Incompatible WAV recordings');
  }
  final size = a.length + b.length;
  final result = Uint8List(44 + size)
    ..setRange(0, 4, 'RIFF'.codeUnits)
    ..setRange(8, 16, 'WAVEfmt '.codeUnits)
    ..setRange(36, 40, 'data'.codeUnits)
    ..setRange(44, 44 + a.length, first, a.offset)
    ..setRange(44 + a.length, 44 + size, second, b.offset);
  ByteData.sublistView(result)
    ..setUint32(4, 36 + size, Endian.little)
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, a.channels, Endian.little)
    ..setUint32(24, a.sampleRate, Endian.little)
    ..setUint32(28, a.sampleRate * a.frameBytes, Endian.little)
    ..setUint16(32, a.frameBytes, Endian.little)
    ..setUint16(34, 16, Endian.little)
    ..setUint32(40, size, Endian.little);
  return result;
}

class _PcmWave {
  const _PcmWave(this.channels, this.sampleRate, this.offset, this.length);

  final int channels;
  final int sampleRate;
  final int offset;
  final int length;
  int get frameBytes => 2 * channels;

  static _PcmWave? read(Uint8List bytes) {
    if (bytes.length < 44) return null;
    final data = ByteData.sublistView(bytes);
    if (data.getUint32(0) != 0x52494646 || data.getUint32(8) != 0x57415645) {
      return null;
    }
    final end = data.getUint32(4, Endian.little) + 8;
    if (end > bytes.length) return null;

    var channels = 0;
    var sampleRate = 0;
    var pcmStart = 0;
    var pcmLength = 0;
    var chunk = 12;
    while (chunk + 8 <= end) {
      final tag = data.getUint32(chunk);
      final length = data.getUint32(chunk + 4, Endian.little);
      final start = chunk + 8;
      if (start + length > end) return null;
      if (tag == 0x666d7420) {
        if (length < 16 ||
            data.getUint16(start, Endian.little) != 1 ||
            data.getUint16(start + 14, Endian.little) != 16) {
          return null;
        }
        channels = data.getUint16(start + 2, Endian.little);
        sampleRate = data.getUint32(start + 4, Endian.little);
      } else if (tag == 0x64617461) {
        pcmStart = start;
        pcmLength = length;
      }
      chunk = start + length + (length.isOdd ? 1 : 0);
    }
    if (channels < 1 ||
        sampleRate < 1 ||
        pcmLength == 0 ||
        pcmLength % (2 * channels) != 0) {
      return null;
    }
    return _PcmWave(channels, sampleRate, pcmStart, pcmLength);
  }
}
