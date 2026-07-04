// lib/screens/widgets/attachment_preview.dart

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/chat_message.dart';
import '../../core/attachment_model.dart';

// Horizontal scrollable strip of pending attachments above the input.
class AttachmentPreviewStrip extends StatelessWidget {
  final List<Attachment> attachments;
  final ValueChanged<int> onRemove;

  const AttachmentPreviewStrip({
    super.key,
    required this.attachments,
    required this.onRemove,
  });

  // Constant chip dimensions
  static const double _chipSize = 72.0;
  static const double _chipSpacing = 8.0;
  static const double _stripHeight = _chipSize + 8.0;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: _stripHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              physics: const BouncingScrollPhysics(),
              itemCount: attachments.length,
              separatorBuilder: (_, __) => const SizedBox(width: _chipSpacing),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: _chipSize,
                  height: _chipSize,
                  child: _AttachmentChip(
                    attachment: attachments[index],
                    onRemove: () => onRemove(index),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// Individual chip using ClipRRect and overlays
class _AttachmentChip extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback onRemove;

  const _AttachmentChip({required this.attachment, required this.onRemove});

  static const double _size = 72.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Base thumbnail
            _buildThumbnail(),

            // 2. Uploading overlay
            if (_isInFlight) _buildUploadingOverlay(),

            // 3. Failed overlay
            if (attachment.status == UploadStatus.failed) _buildFailedOverlay(),

            // 4. Remove button
            Positioned(
              top: 2,
              right: 2,
              child: _RemoveButton(onTap: onRemove),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Removed .processing as it no longer exists in UploadStatus enum
  bool get _isInFlight => attachment.status == UploadStatus.uploading;

  // Thumbnail renderer
  Widget _buildThumbnail() {
    // FIXED: Replaced .isImage with enum check
    if (attachment.type == AttachmentType.image) {
      // Local file first for immediate preview
      final local = attachment.localFile;
      if (local != null && local.existsSync()) {
        return Image.file(
          local,
          fit: BoxFit.cover,
          cacheWidth: 256,
          errorBuilder: (_, __, ___) => _placeholder(Icons.broken_image_outlined),
        );
      }
      // Remote thumbnail using the new .url property from attachment_model.dart
      final url = attachment.url;
      if (url != null && url.isNotEmpty) {
        return CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          memCacheWidth: 256,
          placeholder: (_, __) => _placeholder(Icons.image_outlined),
          errorWidget: (_, __, ___) => _placeholder(Icons.broken_image_outlined),
        );
      }
      return _placeholder(Icons.image_outlined);
    }

    // FIXED: Replaced .isPdf with enum check
    if (attachment.type == AttachmentType.pdf) {
      return Container(
        color: AttachmentColors.pdfBg,
        child: const Center(
          child: Icon(
            Icons.picture_as_pdf,
            color: AttachmentColors.pdfIcon,
            size: 28,
          ),
        ),
      );
    }

    if (attachment.type == AttachmentType.text) {
      return Container(
        color: const Color(0xFF1F2A3A),
        child: const Center(
          child: Icon(
            Icons.description_outlined,
            color: Color(0xFF7FA8FF),
            size: 28,
          ),
        ),
      );
    }

    return _placeholder(Icons.insert_drive_file_outlined);
  }

  // Uploading progress overlay
  Widget _buildUploadingOverlay() {
    final progress = attachment.progress.clamp(0.0, 1.0);

    return Container(
      color: Colors.black.withOpacity(0.65),
      child: Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  value: 1.0,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  value: progress,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFailedOverlay() {
    return Container(
      color: Colors.red.withOpacity(0.75),
      child: const Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _placeholder(IconData icon) {
    return Container(
      color: AttachmentColors.tileBg,
      child: Center(child: Icon(icon, color: Colors.white54, size: 24)),
    );
  }
}

// Remove button widget
class _RemoveButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RemoveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: const Icon(Icons.close, size: 14, color: Colors.white),
        ),
      ),
    );
  }
}
