import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/theme/app_colors.dart';
import '../domain/entities/attachment_photo.dart';

typedef AttachmentPhotoLoader =
    Future<Uint8List> Function(String fileId, {required bool thumbnail});

class AttachmentPhotoGallery extends StatelessWidget {
  const AttachmentPhotoGallery({
    super.key,
    required this.photos,
    required this.loadPhoto,
  });

  final List<AttachmentPhoto> photos;
  final AttachmentPhotoLoader loadPhoto;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 118,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: photos.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final photo = photos[index];
        return SizedBox(
          width: 112,
          child: Column(
            children: [
              Material(
                color: AppColors.dividerMint,
                borderRadius: BorderRadius.circular(10),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _open(context, photo),
                  child: SizedBox(
                    width: 112,
                    height: 88,
                    child: _RemotePhoto(
                      key: ValueKey(photo.id),
                      load: () => loadPhoto(photo.id, thumbnail: true),
                      thumbnail: true,
                      label: photo.fileName,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                photo.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    ),
  );

  Future<void> _open(BuildContext context, AttachmentPhoto photo) =>
      showDialog<void>(
        context: context,
        builder: (context) => Dialog.fullscreen(
          child: Scaffold(
            backgroundColor: AppColors.scaffold,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(photo.fileName),
              actions: [
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            body: SafeArea(
              child: _RemotePhoto(
                load: () => loadPhoto(photo.id, thumbnail: false),
                thumbnail: false,
                label: photo.fileName,
              ),
            ),
          ),
        ),
      );
}

class _RemotePhoto extends StatefulWidget {
  const _RemotePhoto({
    super.key,
    required this.load,
    required this.thumbnail,
    required this.label,
  });

  final Future<Uint8List> Function() load;
  final bool thumbnail;
  final String label;

  @override
  State<_RemotePhoto> createState() => _RemotePhotoState();
}

class _RemotePhotoState extends State<_RemotePhoto> {
  late Future<Uint8List> _photo;

  @override
  void initState() {
    super.initState();
    _photo = widget.load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    future: _photo,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }
      final bytes = snapshot.data;
      if (bytes == null) return _unavailable();
      final image = Image.memory(
        bytes,
        semanticLabel: widget.label,
        fit: widget.thumbnail ? BoxFit.cover : BoxFit.contain,
        errorBuilder: (_, _, _) => _unavailable(),
      );
      if (widget.thumbnail) return image;
      return InteractiveViewer(child: SizedBox.expand(child: image));
    },
  );

  Widget _unavailable() {
    if (widget.thumbnail) {
      return Tooltip(
        message: 'erp_task_photo_unavailable'.tr,
        child: const Center(child: Icon(Icons.broken_image_outlined)),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('erp_task_photo_unavailable'.tr),
          TextButton(
            onPressed: () => setState(() {
              _photo = widget.load();
            }),
            child: Text('erp_task_retry'.tr),
          ),
        ],
      ),
    );
  }
}
