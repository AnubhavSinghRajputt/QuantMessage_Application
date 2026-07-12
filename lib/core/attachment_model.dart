// lib/core/attachment_model.dart
// Attachment model for QuantMessage AI
// Synchronized with:
// • upload_service.dart (Orchestration)
// • quant_space_api.dart (Supabase Storage)
// • chat_screen.dart & incognito_screen.dart (Multimodal Prompts)
// ------------------------------------------------------------------------------

import 'dart:io';
import 'dart:typed_data'; // Added for Uint8List support in Incognito/Web
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

/// Define the type of attachment for UI iconography and AI processing
enum AttachmentType { image, pdf, text, unknown }

/// Track the upload lifecycle for UI progress bars and "Ready" states
enum UploadStatus { pending, uploading, success, failed }

/// The core Attachment model
/// Represents a file from the moment it is picked until it is processed by the AI.
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

  // ──────────────────────────────────────────────────────────────────────────
  //  INTEGRATION HELPERS
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns true if the file is fully uploaded and has a valid URL for the AI.
  bool get isReady => status == UploadStatus.success && url != null;

  /// Generates the specific string fragment the AI expects to "see" the file.
  /// Used in ChatScreen and IncognitoScreen to build the final prompt.
  String get promptFragment => url != null ? "\n[File: $url]" : "";

  /// copyWith allows the UI to update status and progress without recreating the object.
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

// ──────────────────────────────────────────────────────────────────────────
//  CONVENIENCE EXTENSIONS (Factory Methods)
// ──────────────────────────────────────────────────────────────────────────

extension AttachmentX on Attachment {
  /// Creates an Attachment from a local File (Used in ChatScreen)
  static Attachment fromFile(File file, {String? mimeOverride}) {
    final filename = p.basename(file.path);
    final mime = mimeOverride ?? _mimeFromPath(file.path);
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

  /// Creates an Attachment from bytes (Used in IncognitoScreen / Web)
  static Attachment fromBytes(Uint8List bytes, String filename, String mimeType) {
    return Attachment(
      filename: filename,
      type: _typeFromMime(mimeType),
      mimeType: mimeType,
      sizeBytes: bytes.length,
      status: UploadStatus.pending,
    );
  }

  /// Maps a MIME string to an AttachmentType (Synchronized with UploadService)
  static AttachmentType _typeFromMime(String mime) {
    if (mime == 'application/pdf') return AttachmentType.pdf;
    if (mime.startsWith('image/')) return AttachmentType.image;
    if (mime.startsWith('text/')) return AttachmentType.text;
    return AttachmentType.unknown;
  }

  /// Resolves MIME type from path using the mime package
  static String _mimeFromPath(String filePath) {
    return lookupMimeType(filePath) ?? 'application/octet-stream';
  }
}

// ──────────────────────────────────────────────────────────────────────────
//  THEME CONSTANTS
// ──────────────────────────────────────────────────────────────────────────

/// Color palette used by attachment tiles to match the QuantMessage dark theme.
class AttachmentColors {
  static const pdfBg = Color(0xFF3A2418);
  static const pdfIcon = Color(0xFFE27457);
  static const tileBg = Color(0xFF2A2A2A);
  static const borderColor = Color(0x1AFFFFFF); // white.withOpacity(0.1)
}
