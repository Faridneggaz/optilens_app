import 'dart:typed_data';

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
