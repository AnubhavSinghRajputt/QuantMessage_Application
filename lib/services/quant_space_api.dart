// lib/services/quant_space_api.dart
//
// QuantMessage — Backend API client (Integrated with Flowise AI & Supabase)
// -----------------------------------------------------------------------

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Convenience type aliases for cleaner code ───────
typedef _Dio                       = dio_pkg.Dio;
typedef _BaseOptions               = dio_pkg.BaseOptions;
typedef _Options                   = dio_pkg.Options;
typedef _FormData                  = dio_pkg.FormData;
typedef _DioException              = dio_pkg.DioException;
typedef _RequestOptions            = dio_pkg.RequestOptions;
typedef _RequestInterceptorHandler = dio_pkg.RequestInterceptorHandler;
typedef _ErrorInterceptorHandler   = dio_pkg.ErrorInterceptorHandler;

class QuantSpaceApi {
  late final _Dio _dio;

  // Credentials pulled from .env
  String get flowiseUrl => dotenv.env['FLOWISE_URL'] ?? '';
  String get flowiseApiKey => dotenv.env['FLOWISE_API_KEY'] ?? '';
  String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  QuantSpaceApi() {
    _dio = _Dio(
      _BaseOptions(
        baseUrl: '', // We use full URLs for different endpoints
        headers: {'Content-Type': 'application/json'},
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );

    // Attach the Supabase Auth Interceptor to all Dio requests
    _dio.interceptors.add(_AuthInterceptor());
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  CORE AI INTEGRATION (Flowise)
  // ──────────────────────────────────────────────────────────────────────────

  Future<String> getAIResponse(String message, String userId) async {
    if (flowiseUrl.isEmpty) {
      return "🚨 Configuration Error: FLOWISE_URL is missing in .env file.";
    }

    try {
      final response = await _dio.post(
        flowiseUrl,
        data: {
          "question": message,
          "overrideConfig": {
            "sessionId": userId, // This ensures the AI remembers the user session
          },
        },
        options: _Options(
          headers: {
            "Authorization": "Bearer $flowiseApiKey",
          },
        ),
      );

      // Flowise can return a simple string or a JSON map
      if (response.data is String) {
        return response.data;
      } else if (response.data is Map) {
        return response.data['text'] ?? response.data['content'] ?? response.data.toString();
      }

      return response.data.toString();
    } on _DioException catch (e) {
      debugPrint('[QuantSpace API] Flowise Error: ${e.response?.data ?? e.message}');
      return "🚨 AI Error: ${e.message ?? 'Unknown error occurred'}";
    } catch (e) {
      debugPrint('[QuantSpace API] Unexpected Error: $e');
      return "🚨 System Error: $e";
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  MULTIMODAL & FILE HANDLING (Supabase Storage)
  // ──────────────────────────────────────────────────────────────────────────

  /// Uploads a file to Supabase Storage and returns the Public URL
  Future<Map<String, dynamic>> uploadFile(String filePath, {required String conversationId}) async {
    try {
      // 1. Extract the filename from the path
      final fileName = p.basename(filePath);

      // 2. Create a dart:io File object
      final file = File(filePath);

      // 3. Upload to Supabase Storage
      // NOTE: Make sure you have created a bucket named 'attachments' in Supabase Dashboard
      final storage = Supabase.instance.client.storage.from('attachments');

      // We organize files by conversationId to keep the storage clean
      final path = 'conversations/$conversationId/$fileName';

      await storage.upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      // 4. Generate the Public URL to send to the AI model
      final publicUrl = storage.getPublicUrl(path);

      return {
        'url': publicUrl,
        'status': 'success',
        'message': 'File uploaded successfully',
      };
    } catch (e) {
      debugPrint('[QuantSpace API] Upload Error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  COMPATIBILITY LAYER (For older parts of the app)
  // ──────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> chat(String message, {String? model}) async {
    final responseText = await getAIResponse(message, "legacy_session");
    return {
      'content': responseText,
      'conversation_id': 'flowise_session',
    };
  }

  Future<Map<String, dynamic>> chatSimple(String text, {String? model}) async {
    return await chat(text, model: model);
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  OTHER UTILITIES
  // ──────────────────────────────────────────────────────────────────────────

  Future<String?> generateImage(String prompt) async {
    final response = await getAIResponse("Generate a high-quality AI image: $prompt", "image_session");

    // Regular expression to find Markdown images [alt](url)
    final RegExp urlRegex = RegExp(r'!\[.*?\]\((.*?)\)');
    final Match? match = urlRegex.firstMatch(response);
    return match?.group(1) ?? response;
  }

  void resetSession() {
    debugPrint('[QuantSpace API] Session Reset Requested');
  }

  void dispose() => _dio.close();
}

// ─────────────────────────────────────────────────────────────────────────────
//  Auth Interceptor (Links Supabase Auth to API Requests)
// ─────────────────────────────────────────────────────────────────────────────
class _AuthInterceptor extends dio_pkg.Interceptor {
  @override
  void onRequest(_RequestOptions options, _RequestInterceptorHandler handler) {
    try {
      // Pull the current session from the Supabase singleton initialized in main.dart
      final session = Supabase.instance.client.auth.currentSession;
      if (session?.accessToken != null) {
        options.headers['Authorization'] = 'Bearer ${session!.accessToken}';
      }
    } catch (e) {
      debugPrint('[QuantSpace API] Auth Interceptor Error: $e');
    }
    handler.next(options);
  }

  @override
  void onError(_DioException err, _ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      debugPrint('[QuantSpace API] 401 Unauthorized - Session may have expired');
    }
    handler.next(err);
  }
}
