// lib/screens/widgets/attachment_thumbnail.dart

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../core/chat_message.dart';
import '../../core/attachment_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AttachmentList — public entry point used inside chat bubbles
// ─────────────────────────────────────────────────────────────────────────────

class AttachmentList extends StatelessWidget {
  final List<Attachment> attachments;

  const AttachmentList({super.key, required this.attachments});

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: attachments.map((a) => _AttachmentTile(attachment: a)).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tile widget
// ─────────────────────────────────────────────────────────────────────────────

class _AttachmentTile extends StatelessWidget {
  final Attachment attachment;
  const _AttachmentTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    // FIXED: Replaced .isImage and .isPdf with Enum checks from attachment_model.dart
    if (attachment.type == AttachmentType.image) return _ImageTile(attachment: attachment);
    if (attachment.type == AttachmentType.pdf) return _PdfTile(attachment: attachment);
    return _GenericTile(attachment: attachment);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Image tile
// ─────────────────────────────────────────────────────────────────────────────

class _ImageTile extends StatelessWidget {
  final Attachment attachment;
  const _ImageTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    // FIXED: Replaced remoteUrl and thumbnailUrl with the new .url property
    final url = attachment.url;
    final localFile = attachment.localFile;

    final hasNetwork = url != null && url.isNotEmpty;
    final hasLocal = localFile != null && localFile.existsSync();

    if (!hasNetwork && !hasLocal) {
      return _ErrorTile(
        icon: Icons.broken_image_outlined,
        label: 'Image unavailable',
      );
    }

    return GestureDetector(
      onTap: () => _openFullScreen(context, url, localFile),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Simplified constraints logic to avoid casting errors
            final double maxW = constraints.maxWidth.isFinite
                ? constraints.maxWidth.clamp(0.0, 260.0)
                : 260.0;

            return Container(
              constraints: BoxConstraints(
                maxWidth: maxW,
                maxHeight: maxW,
              ),
              child: hasNetwork
                  ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                memCacheWidth: 800,
                placeholder: (_, __) => const _LoadingTile(),
                errorWidget: (_, __, ___) => _ErrorTile(icon: Icons.broken_image_outlined),
              )
                  : Image.file(
                localFile!,
                fit: BoxFit.cover,
                cacheWidth: 800,
                errorBuilder: (_, __, ___) => _ErrorTile(icon: Icons.broken_image_outlined),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context, String? url, File? localFile) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) => FullImageViewer(
          url: url,
          localFile: localFile,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PDF tile
// ─────────────────────────────────────────────────────────────────────────────

class _PdfTile extends StatelessWidget {
  final Attachment attachment;
  const _PdfTile({required this.attachment});

  // Helper to solve "sizeFormatted" error by implementing the logic here
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    // FIXED: Replaced remoteUrl with .url
    final url = attachment.url;
    if (url == null || url.isEmpty) return _ErrorTile(icon: Icons.error_outline);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => PdfViewerScreen(
              url: url,
              filename: attachment.filename,
            ),
          ),
        );
      },
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AttachmentColors.tileBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AttachmentColors.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AttachmentColors.pdfBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.picture_as_pdf, color: AttachmentColors.pdfIcon, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    attachment.filename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatSize(attachment.sizeBytes), // FIXED: Custom formatter to solve sizeFormatted error
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.visibility_outlined, color: Colors.white.withOpacity(0.6), size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Generic file tile
// ─────────────────────────────────────────────────────────────────────────────

class _GenericTile extends StatelessWidget {
  final Attachment attachment;
  const _GenericTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AttachmentColors.tileBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file_outlined, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              attachment.filename,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared mini widgets
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AttachmentColors.tileBg,
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  final IconData icon;
  final String? label;
  const _ErrorTile({required this.icon, this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AttachmentColors.tileBg,
      width: 120,
      height: 120,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 24),
            if (label != null) ...[
              const SizedBox(height: 4),
              Text(label!, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Full-screen image viewer
// ─────────────────────────────────────────────────────────────────────────────

class FullImageViewer extends StatefulWidget {
  final String? url;
  final File? localFile;

  const FullImageViewer({super.key, this.url, this.localFile})
      : assert(url != null || localFile != null, 'Provide either url or localFile');

  @override
  State<FullImageViewer> createState() => _FullImageViewerState();
}

class _FullImageViewerState extends State<FullImageViewer> {
  late final TransformationController _transformCtrl;

  @override
  void initState() {
    super.initState();
    _transformCtrl = TransformationController();
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _transformCtrl,
                minScale: 1.0,
                maxScale: 5.0,
                child: Center(child: _buildImage()),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.url != null && widget.url!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.url!,
        fit: BoxFit.contain,
        memCacheWidth: 2048,
        placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white)),
        errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64)),
      );
    }
    return Image.file(
      widget.localFile!,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Full-screen PDF viewer
// ─────────────────────────────────────────────────────────────────────────────

class PdfViewerScreen extends StatefulWidget {
  final String url;
  final String filename;

  const PdfViewerScreen({super.key, required this.url, required this.filename});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final GlobalKey<SfPdfViewerState> _pdfKey = GlobalKey();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(widget.filename, style: const TextStyle(color: Colors.white, fontSize: 15), overflow: TextOverflow.ellipsis),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SfPdfViewer.network(
            widget.url,
            key: _pdfKey,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            canShowPaginationDialog: true,
            onDocumentLoaded: (_) {
              if (mounted) setState(() => _loading = false);
            },
            onDocumentLoadFailed: (details) {
              if (mounted) setState(() => _loading = false);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load PDF: ${details.error}')));
            },
          ),
          if (_loading)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)),
                  SizedBox(height: 16),
                  Text('Loading document...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
