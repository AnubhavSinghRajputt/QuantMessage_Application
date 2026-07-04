// lib/core/attachment_model.dart
// Attachment model for QuantMessage AI
// Handles file metadata, upload status, and MIME type resolution

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

// Enum to define the type of attachment for UI iconography
enum AttachmentType { image, pdf, text, unknown }

// Enum to track the upload lifecycle for the UI progress bars
enum UploadStatus { pending, uploading, success, failed }

// The core Attachment model
class Attachment {
  final String filename;
  final AttachmentType type;
  final String mimeType;
  final int sizeBytes;
  final UploadStatus status;
  final File? localFile;
  final double progress;
  final String? url; // The public Supabase URL after upload

  Attachment({
    required this.filename,
    required this.type,
    required this.mimeType,
    required this.sizeBytes,
    this.status = UploadStatus.pending,
    this.localFile,
    this.progress = 0.0,
    this.url,
  });

  // Getter to check if the file is fully uploaded and ready for the AI
  bool get isReady => status == UploadStatus.success && url != null;

  // copyWith allows the UI to update status and progress without recreating the whole object
  Attachment copyWith({
    String? filename,
    AttachmentType? type,
    String? mimeType,
    int? sizeBytes,
    UploadStatus? status,
    File? localFile,
    double? progress,
    String? url,
  }) {
    return Attachment(
      filename: filename ?? this.filename,
      type: type ?? this.type,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      status: status ?? this.status,
      localFile: localFile ?? this.localFile,
      progress: progress ?? this.progress,
      url: url ?? this.url,
    );
  }
}

// Convenience helpers for Attachment
extension AttachmentX on Attachment {
  // Creates an Attachment instance from a local File
  static Attachment fromFile(File file, {String? mimeOverride}) {
    // Use path package to safely extract the filename
    final filename = p.basename(file.path);

    // Resolve the MIME type: either the override or a lookup based on the path
    final mime = mimeOverride ?? _mimeFromPath(file.path);

    // Determine the attachment type based on the MIME
    final type = _typeFromMime(mime);

    return Attachment(
      filename: filename,
      type: type,
      mimeType: mime,
      sizeBytes: file.lengthSync(),
      localFile: file,
      status: UploadStatus.pending,
    );
  }

  // Internal helper that maps a MIME string to an AttachmentType
  static AttachmentType _typeFromMime(String mime) {
    if (mime == 'application/pdf') {
      return AttachmentType.pdf;
    } else if (mime.startsWith('image/')) {
      return AttachmentType.image;
    } else if (mime.startsWith('text/')) {
      return AttachmentType.text;
    } else {
      return AttachmentType.unknown;
    }
  }

  // Retrieves the MIME type for a given file path using the mime package
  static String _mimeFromPath(String filePath) {
    return lookupMimeType(filePath) ?? 'application/octet-stream';
  }
}

// Color palette used by attachment tiles to match the QuantMessage dark theme
class AttachmentColors {
  static const pdfBg = Color(0xFF3A2418);
  static const pdfIcon = Color(0xFFE27457);
  static const tileBg = Color(0xFF2A2A2A);
  static const borderColor = Color(0x1AFFFFFF); // white.withOpacity(0.1)
}
