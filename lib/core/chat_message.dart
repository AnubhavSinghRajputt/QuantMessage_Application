// lib/core/chat_message.dart
//
// QuantMessage — Chat data models
// Integrated with attachment_model.dart to ensure a single source of truth.
// ------------------------------------------------------------------------------

import 'attachment_model.dart'; // Import the model to use Attachment, AttachmentType, and UploadStatus

/// The single source of truth for a chat bubble.
/// This class is used by chat_screen.dart to render the conversation.
class ChatMessage {
  final String text;
  final bool isUser;
  final String modelName;
  final List<Attachment> attachments;
  final bool isStreaming;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.modelName = "",
    this.attachments = const [],
    this.isStreaming = false,
  });

  // ──────────────────────────────────────────────────────────────────────────
  //  Getters for UI Logic (Used in chat_screen.dart)
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns true if the message contains any files/images.
  bool get hasAttachments => attachments.isNotEmpty;

  /// Returns true if the message contains actual text (ignoring whitespace).
  bool get hasText => text.trim().isNotEmpty;

  // ──────────────────────────────────────────────────────────────────────────
  //  Utility Methods
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates a copy of the message with updated fields.
  /// Essential for updating the UI when the AI is streaming or attachments are added.
  ChatMessage copyWith({
    String? text,
    List<Attachment>? attachments,
    bool? isStreaming,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser,
      modelName: modelName,
      attachments: attachments ?? this.attachments,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}
