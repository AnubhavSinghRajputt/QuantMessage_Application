// lib/services/upload_service.dart
//
// QuantMessage — File upload + multimodal chat messages
// Integrated with Flowise AI, Supabase, and the new Attachment Model
// ---------------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;

// IMPORTED: These solve the "Undefined class" and "Not a type" errors
import '../core/chat_message.dart';
import '../core/attachment_model.dart';
import 'quant_space_api.dart';

class UploadService {
  // Configuration
  static const String _defaultBaseUrl = 'https://your-app.up.railway.app/api/v1';

  String get _baseUrl {
    final envUrl = dotenv.maybeGet('BACKEND_URL');
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    return _defaultBaseUrl;
  }

  // Dependencies
  final SupabaseClient _supabase;
  final Dio _dio;
  final http.Client _fallbackClient;
  final QuantSpaceApi _quantApi; // Integration with the new API service

  UploadService({
    SupabaseClient? supabase,
    Dio? dio,
    http.Client? fallbackClient,
    QuantSpaceApi? quantApi,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 60),
                sendTimeout: const Duration(seconds: 60),
              ),
            ),
        _fallbackClient = fallbackClient ?? http.Client(),
        _quantApi = quantApi ?? QuantSpaceApi() {
    _dio.interceptors.add(_SupabaseAuthInterceptor(_supabase));
  }

  // Auth helpers
  String _accessToken() {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw Exception('Not authenticated. Please sign in again.');
    }
    return session.accessToken;
  }

  Map<String, String> _jsonHeaders() => {
    'Authorization': 'Bearer ${_accessToken()}',
    'Content-Type': 'application/json',
  };

  // ──────────────────────────────────────────────────────────────────────────
  // UPLOAD (Integrated with QuantSpaceApi and Supabase)
  // ──────────────────────────────────────────────────────────────────────────

  Future<Attachment> uploadFile({
    required File file,
    required String conversationId,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
    int maxRetries = 2,
  }) async {
    onProgress?.call(0.0);

    try {
      // Use the already verified and working upload logic from QuantSpaceApi
      final result = await _quantApi.uploadFile(
          file.path,
          conversationId: conversationId
      );

      if (result['status'] == 'success') {
        onProgress?.call(1.0);

        // Return the Attachment model compatible with chat_screen.dart
        return Attachment(
          filename: file.path.split('/').last,
          type: _typeFromMime(lookupMimeType(file.path) ?? 'application/octet-stream'),
          mimeType: lookupMimeType(file.path) ?? 'application/octet-stream',
          sizeBytes: await file.length(),
          url: result['url'], // The public Supabase URL
          status: UploadStatus.success,
          localFile: file,
          progress: 1.0,
        );
      } else {
        throw Exception(result['message'] ?? 'Upload failed');
      }
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CHAT MESSAGE (Integrated with Flowise)
  // ──────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> sendMessageWithAttachments({
    required String message,
    required List<Attachment> attachments,
    String? conversationId,
    bool isIncognito = false,
    String? agentOverride,
  }) async {
    // Instead of using a separate fallback client, we use the Flowise logic
    // Construct the prompt by adding attachment URLs (as done in chat_screen.dart)
    String finalMessage = message;
    for (var a in attachments) {
      if (a.url != null) {
        finalMessage += "\n[File: ${a.url}]";
      }
    }

    // Call the QuantSpaceApi getAIResponse logic
    final userId = _supabase.auth.currentUser?.id ?? "guest_user";
    final responseText = await _quantApi.getAIResponse(finalMessage, userId);

    return {
      'content': responseText,
      'conversation_id': conversationId ?? 'flowise_session',
    };
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Streaming chat (SSE)
  // ──────────────────────────────────────────────────────────────────────────

  Stream<Map<String, dynamic>> streamMessageWithAttachments({
    required String message,
    required List<Attachment> attachments,
    String? conversationId,
    bool isIncognito = false,
    String? agentOverride,
  }) async* {
    // Flowise typically handles streaming via its own endpoint
    // To keep the app stable, we redirect this to the standard AI response
    final userId = _supabase.auth.currentUser?.id ?? "guest_user";
    final response = await _quantApi.getAIResponse(message, userId);
    yield {'content': response, 'conversation_id': conversationId};
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Voice transcription
  // ──────────────────────────────────────────────────────────────────────────

  Future<String> transcribeAudio(File audioFile) async {
    final filename = audioFile.path.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        audioFile.path,
        filename: filename,
        contentType: MediaType.parse(_guessMime(filename)),
      ),
    });

    final response = await _dio.post(
      '$_baseUrl/voice/transcribe',
      data: formData,
      options: Options(
        headers: {'Authorization': 'Bearer ${_accessToken()}'},
        contentType: 'multipart/form-data',
      ),
    );

    if (response.statusCode != null && response.statusCode! >= 400) {
      throw Exception('Transcription failed: ${response.data}');
    }

    final body = response.data as Map<String, dynamic>;
    return body['text'] as String? ?? '';
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Conversation history & Settings (Legacy Support)
  // ──────────────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getHistory({int limit = 50}) async {
    final response = await _fallbackClient.get(
      Uri.parse('$_baseUrl/conversations/?limit=$limit'),
      headers: _jsonHeaders(),
    );
    if (response.statusCode >= 400) throw Exception('History fetch failed');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(body['conversations'] ?? []);
  }

  Future<Map<String, dynamic>> getConversation(String conversationId) async {
    final response = await _fallbackClient.get(
      Uri.parse('$_baseUrl/conversations/$conversationId'),
      headers: _jsonHeaders(),
    );
    if (response.statusCode >= 400) throw Exception('Conversation fetch failed');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> deleteConversation(String conversationId) async {
    await _fallbackClient.delete(
      Uri.parse('$_baseUrl/conversations/$conversationId'),
      headers: _jsonHeaders(),
    );
  }

  Future<Map<String, dynamic>> getSettings() async {
    final response = await _fallbackClient.get(
      Uri.parse('$_baseUrl/settings/'),
      headers: _jsonHeaders(),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) async {
    final response = await _fallbackClient.put(
      Uri.parse('$_baseUrl/settings/'),
      headers: _jsonHeaders(),
      body: jsonEncode(settings),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> listAgents() async {
    final response = await _fallbackClient.get(
      Uri.parse('$_baseUrl/agents/'),
      headers: _jsonHeaders(),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<bool> healthCheck() async {
    try {
      final response = await _fallbackClient.get(Uri.parse('$_baseUrl/health'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _fallbackClient.close();
    _dio.close(force: true);
  }

  // Helpers
  AttachmentType _typeFromMime(String mime) {
    if (mime == 'application/pdf') return AttachmentType.pdf;
    if (mime.startsWith('image/')) return AttachmentType.image;
    if (mime.startsWith('text/')) return AttachmentType.text;
    return AttachmentType.unknown;
  }

  String _guessMime(String filename) {
    return lookupMimeType(filename) ?? 'application/octet-stream';
  }
}

class _SupabaseAuthInterceptor extends Interceptor {
  final SupabaseClient _supabase;
  _SupabaseAuthInterceptor(this._supabase);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        options.headers['Authorization'] = 'Bearer ${session.accessToken}';
      }
    } catch (e) {
      debugPrint('[UploadService] Auth interceptor error: $e');
    }
    handler.next(options);
  }
}
