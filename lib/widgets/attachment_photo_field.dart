import 'package:flutter/material.dart';
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
    setState(() {
      _picking = true;
      _error = null;
    });
    widget.onPickingChanged?.call(true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'erp_task_photo_pick_error'.tr;
      });
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
