import '../../domain/entities/attachment_photo.dart';

List<AttachmentPhoto> mapAttachmentPhotos(Object? raw) => [
  if (raw case final List photos)
    for (final photo in photos)
      if (photo case {
        'id': final String id,
        'file_name': final String name,
      } when id.isNotEmpty && name.isNotEmpty)
        AttachmentPhoto(id: id, fileName: name),
];
