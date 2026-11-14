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
    required this.photo,
    required this.onChanged,
    this.onPickingChanged,
    this.disabled = false,
  });

  final int maxBytes;
  final SelectedPhoto? photo;
  final ValueChanged<SelectedPhoto?> onChanged;
  final ValueChanged<bool>? onPickingChanged;
  final bool disabled;

  @override
  State<AttachmentPhotoField> createState() => _AttachmentPhotoFieldState();
}

class _AttachmentPhotoFieldState extends State<AttachmentPhotoField> {
  bool _picking = false;
  String? _error;

  Future<void> _pick() async {
    if (_picking || widget.disabled) return;
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
    if (!mounted || source == null || _picking || widget.disabled) return;

    setState(() {
      _picking = true;
      _error = null;
    });
    widget.onPickingChanged?.call(true);
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2560,
        maxHeight: 2560,
        imageQuality: 90,
        requestFullMetadata: false,
      );
      if (image == null || !mounted) return;
      if (await image.length() > widget.maxBytes) {
        if (!mounted) return;
        final limit = (widget.maxBytes / (1024 * 1024)).toStringAsFixed(1);
        setState(() {
          _error = 'erp_task_photo_too_large'.trParams({'limit': limit});
        });
        return;
      }
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      widget.onChanged(SelectedPhoto(name: image.name, bytes: bytes));
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

  @override
  Widget build(BuildContext context) {
    final photo = widget.photo;
    final disabled = widget.disabled || _picking;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photo == null)
          ActionChip(
            avatar: const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: Text('erp_task_add_photo'.tr),
            onPressed: disabled ? null : _pick,
          )
        else
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
            onTap: disabled ? null : _pick,
            trailing: IconButton(
              tooltip: 'erp_task_remove_photo'.tr,
              onPressed: disabled
                  ? null
                  : () {
                      setState(() => _error = null);
                      widget.onChanged(null);
                    },
              icon: const Icon(Icons.close),
            ),
          ),
        if (_error case final String error)
          Text(error, style: const TextStyle(color: AppColors.danger)),
      ],
    );
  }
}
