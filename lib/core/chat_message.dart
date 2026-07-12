// lib/core/chat_message.dart
//
// QuantMessage — Chat data models
// Synchronized with:
// • Supabase 'chat_messages' table schema
// • QuantSpaceApi (Flowise responses)
// • HistoryScreen (Data retrieval)
// • ChatScreen (Real-time interaction)
// ------------------------------------------------------------------------------

import 'attachment_model.dart';

/// The single source of truth for a chat message.
/// This class handles the mapping between the Supabase PostgreSQL
/// database and the Flutter UI.
class ChatMessage {
  // Database Identifiers
  final String? id;              // Primary key from Supabase
  final String conversationId;   // Groups messages into one chat session
  final String senderId;         // UUID of the user or 'agent'
  final DateTime createdAt;      // Timestamp for sorting in HistoryScreen

  // Content
  final String text;             // The actual message content
  final bool isUser;             // UI helper: true if sender is the user
  final String modelName;        // The AI model used (e.g., 'GPT-4o')
  final List<Attachment> attachments;
  final bool isStreaming;

  ChatMessage({
    this.id,
    required this.conversationId,
    required this.senderId,
    required this.createdAt,
    required this.text,
    required this.isUser,
    this.modelName = "QuantCore",
    this.attachments = const [],
    this.isStreaming = false,
  });

  // ──────────────────────────────────────────────────────────────────────────
  //  SUPABASE INTEGRATION (Serialization)
  // ──────────────────────────────────────────────────────────────────────────

  /// Converts a Supabase database row (Map) into a ChatMessage object.
  /// Used heavily in HistoryScreen.
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id']?.toString(),
      conversationId: map['conversation_id'] ?? '',
      senderId: map['sender_uuid'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      text: map['content'] ?? '',
      isUser: map['role'] == 'user',
      modelName: (map['metadata'] as Map?)?['model'] ?? 'QuantCore',
      attachments: [], // Attachments are usually handled via a separate join or URL parsing
      isStreaming: false,
    );
  }

  /// Converts a ChatMessage object into a Map for Supabase insertion.
  /// Used in ChatScreen during _handleSend.
  Map<String, dynamic> toMap() {
    return {
      'conversation_id': conversationId,
      'sender_uuid': senderId,
      'role': isUser ? 'user' : 'agent',
      'content': text,
      'created_at': createdAt.toIso8601String(),
      'metadata': {
        'model': modelName,
      },
    };
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  UI LOGIC GETTERS
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns true if the message contains any files/images.
  bool get hasAttachments => attachments.isNotEmpty;

  /// Returns true if the message contains actual text (ignoring whitespace).
  bool get hasText => text.trim().isNotEmpty;

  // ──────────────────────────────────────────────────────────────────────────
  //  UTILITY METHODS
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates a copy of the message with updated fields.
  /// Essential for updating the UI when the AI is streaming.
  ChatMessage copyWith({
    String? text,
    List<Attachment>? attachments,
    bool? isStreaming,
    String? modelName,
  }) {
    return ChatMessage(
      id: this.id,
      conversationId: this.conversationId,
      senderId: this.senderId,
      createdAt: this.createdAt,
      text: text ?? this.text,
      isUser: this.isUser,
      modelName: modelName ?? this.modelName,
      attachments: attachments ?? this.attachments,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}
