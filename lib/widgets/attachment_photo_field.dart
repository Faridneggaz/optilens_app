import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/app_colors.dart';
import '../domain/entities/attachment_photo.dart';

class AttachmentPhotoField extends StatefulWidget {
  const AttachmentPhotoField({
    super.key,
    required this.maxBytes,
    required this.photos,
    this.maxBatchBytes = 0,
    this.maxCount = 1,
    required this.onChanged,
    this.onPickingChanged,
    this.disabled = false,
  });

  final int maxBytes;
  final int maxBatchBytes;
  final int maxCount;
  final List<SelectedPhoto> photos;
  final ValueChanged<List<SelectedPhoto>> onChanged;
  final ValueChanged<bool>? onPickingChanged;
  final bool disabled;

  @override
  State<AttachmentPhotoField> createState() => _AttachmentPhotoFieldState();
}

class _AttachmentPhotoFieldState extends State<AttachmentPhotoField> {
  bool _picking = false;
  String? _error;

  Future<void> _pick() async {
    final remaining = widget.maxCount - widget.photos.length;
    if (_picking || widget.disabled || remaining <= 0) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    widget.onPickingChanged?.call(true);
    try {
      final canTakePhoto =
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS);
      final source = canTakePhoto
          ? await showModalBottomSheet<ImageSource>(
              context: context,
              builder: (sheetContext) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.photo_camera_outlined),
                      title: Text('attachment_take_photo'.tr),
                      onTap: () =>
                          Navigator.pop(sheetContext, ImageSource.camera),
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo_library_outlined),
                      title: Text('attachment_choose_gallery'.tr),
                      onTap: () =>
                          Navigator.pop(sheetContext, ImageSource.gallery),
                    ),
                  ],
                ),
              ),
            )
          : ImageSource.gallery;
      if (!mounted || source == null || widget.disabled) return;

      final picker = ImagePicker();
      final List<XFile> images;
      if (source == ImageSource.gallery && remaining > 1) {
        images = await picker.pickMultiImage(
          limit: remaining,
          maxWidth: 2560,
          maxHeight: 2560,
          imageQuality: 90,
          requestFullMetadata: false,
        );
      } else {
        final image = await picker.pickImage(
          source: source,
          maxWidth: 2560,
          maxHeight: 2560,
          imageQuality: 90,
          requestFullMetadata: false,
        );
        images = [if (image != null) image];
      }
      if (!mounted || images.isEmpty) return;
      await _addPhotos(images);
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = switch (error.code) {
          'camera_access_denied' ||
          'camera_access_restricted' => 'attachment_camera_denied'.tr,
          'no_available_camera' => 'attachment_camera_unavailable'.tr,
          _ => 'erp_task_photo_pick_error'.tr,
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'erp_task_photo_pick_error'.tr);
    } finally {
      if (mounted) {
        setState(() => _picking = false);
        widget.onPickingChanged?.call(false);
      }
    }
  }

  Future<void> _addPhotos(List<XFile> images) async {
    final selected = [...widget.photos];
    final batchLimit = widget.maxBatchBytes > 0
        ? widget.maxBatchBytes
        : widget.maxBytes;
    var totalBytes = selected.fold<int>(
      0,
      (sum, photo) => sum + photo.bytes.length,
    );
    String? error;

    for (final image in images) {
      if (selected.length == widget.maxCount) {
        error ??= _countLimit;
        break;
      }
      final length = await image.length();
      if (!mounted) return;
      if (length > widget.maxBytes) {
        error ??= _sizeError('erp_task_photo_too_large', widget.maxBytes);
        continue;
      }
      if (totalBytes + length > batchLimit) {
        error ??= _sizeError('attachment_batch_too_large', batchLimit);
        continue;
      }
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      selected.add(SelectedPhoto(name: image.name, bytes: bytes));
      totalBytes += bytes.length;
    }

    setState(() => _error = error);
    widget.onChanged(selected);
  }

  String _sizeError(String key, int bytes) =>
      key.trParams({'limit': (bytes / (1024 * 1024)).toStringAsFixed(1)});

  String get _countLimit => 'attachment_photo_count_limit'.trParams({
    'count': widget.maxCount.toString(),
  });

  @override
  Widget build(BuildContext context) {
    final disabled = widget.disabled || _picking;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final photo in widget.photos)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                photo.bytes,
                width: 48,
                height: 48,
                cacheWidth: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.image_outlined),
              ),
            ),
            title: Text(
              photo.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            trailing: IconButton(
              tooltip: 'erp_task_remove_photo'.tr,
              onPressed: disabled
                  ? null
                  : () {
                      setState(() => _error = null);
                      widget.onChanged(
                        widget.photos.where((item) => item != photo).toList(),
                      );
                    },
              icon: const Icon(Icons.close),
            ),
          ),
        if (widget.photos.length < widget.maxCount)
          ActionChip(
            avatar: const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: Text('erp_task_add_photo'.tr),
            onPressed: disabled ? null : _pick,
          )
        else if (_error == null && widget.maxCount > 1)
          Text(_countLimit),
        if (_error case final String error)
          Text(error, style: const TextStyle(color: AppColors.danger)),
      ],
    );
  }
}
