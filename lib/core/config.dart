// lib/core/config.dart
//
// Central configuration hub – reads the `.env` file (flutter_dotenv) and
// exposes typed, static getters used throughout the app.
//
// Synchronized with:
// • main.dart (Initialization)
// • quant_space_api.dart (AI Endpoint & API Keys)
// • upload_service.dart (Backend URL & Storage)
// • chat_screen.dart & home_screen.dart (Model Selection)
// • settings_screen.dart (User Profiles)
// • chat_message.dart & attachment_model.dart (Data Structure)

import 'package:flutter/foundation.dart'; // FIXED: Removed 'show kIsWeb' to enable debugPrint
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  Config._(); // private constructor – this class is never instantiated

  /// Initialize the .env file.
  /// Call this in main() before Supabase.initialize().
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      // This now works because we imported the full foundation library
      debugPrint("🚨 Config Error: Could not load .env file. Check if it exists in root.");
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ☁️ SUPABASE CREDENTIALS
  // ──────────────────────────────────────────────────────────────────────────

  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://your-project.supabase.co';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// SERVICE_ROLE_KEY should ONLY be used in Edge Functions, never in the Flutter App.
  static String? get supabaseServiceRoleKey => dotenv.env['SUPABASE_SERVICE_ROLE_KEY'];

  // ──────────────────────────────────────────────────────────────────────────
  // 🤖 FLOWISE AI CREDENTIALS
  // ──────────────────────────────────────────────────────────────────────────

  static String get flowiseUrl =>
      dotenv.env['FLOWISE_URL'] ?? 'https://cloud.flowiseai.com/api/v1/prediction/';

  static String get flowiseApiKey =>
      dotenv.env['FLOWISE_API_KEY'] ?? '';

  // ──────────────────────────────────────────────────────────────────────────
  // 🌐 BACKEND API (Railway/Custom Server)
  // ──────────────────────────────────────────────────────────────────────────

  /// Used by UploadService for transcription and custom API endpoints.
  static String get backendUrl =>
      dotenv.env['BACKEND_URL'] ?? 'https://your-app.up.railway.app/api/v1';

  // ──────────────────────────────────────────────────────────────────────────
  // 🛠️ UTILITIES & PLATFORM
  // ──────────────────────────────────────────────────────────────────────────

  /// Platform helper – useful when you need to branch for web vs mobile.
  static bool get isWeb => kIsWeb;

  /// The definitive list of AI Models.
  /// This list is used by ChatScreen and HomeScreen to populate the dropdowns.
  static List<AiModel> get models => [
    const AiModel(
        name: 'QuantCore 1.0',
        id: 'groq/llama-3.1-70b-versatile',
        icon: '⚡',
        description: 'Groq Llama 3.1 70B, Versatile Quant Expert'),
    const AiModel(
        name: 'GPT‑4o',
        id: 'openai/gpt-4o',
        icon: '🧠',
        description: 'OpenAI latest multimodal model'),
    const AiModel(
        name: 'Claude 3.5 Sonnet',
        id: 'anthropic/claude-3.5-sonnet',
        icon: '🎭',
        description: 'Anthropic’s high‑quality assistant'),
    const AiModel(
        name: 'Llama 3.1 8B',
        id: 'groq/llama-3.1-8b-instant',
        icon: '🚀',
        description: 'Fast, inexpensive Llama 8B'),
    const AiModel(
        name: 'Mixtral 8x7B',
        id: 'groq/mixtral-8x7b-32768',
        icon: '🔥',
        description: 'Mixture‑of‑experts, great reasoning'),
    const AiModel(
        name: 'DeepSeek Chat',
        id: 'deepseek-chat',
        icon: '🤖',
        description: 'Open‑source‑focused large model'),
  ];
}

// Simple value‑object that describes an AI model
class AiModel {
  final String name;
  final String id;
  final String icon;
  final String description;

  const AiModel({
    required this.name,
    required this.id,
    required this.icon,
    required this.description,
  });
}
