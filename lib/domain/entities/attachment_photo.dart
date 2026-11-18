import 'dart:typed_data';

int attachmentUploadBytes(List<SelectedPhoto> photos, List<Uint8List> voices) =>
    photos.fold(0, (size, photo) => size + photo.bytes.length) +
    voices.fold(0, (size, voice) => size + voice.length);

class AttachmentPhoto {
  const AttachmentPhoto({required this.id, required this.fileName});
  final String id;
  final String fileName;
}

class SelectedPhoto {
  const SelectedPhoto({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
}
