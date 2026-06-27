// lib/main.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import 'services/quant_space_api.dart';
import 'core/app_theme.dart';
import 'screens/splash_screen.dart';// 
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/app_bar.dart';

void main() {
  runApp(const ProviderScope(child: QuantSpaceApp()));
}

class QuantSpaceApp extends StatelessWidget {
  const QuantSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuantCore.Ai',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppTheme.primaryRed,
        scaffoldBackgroundColor: AppTheme.backgroundBlack,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryRed,
          brightness: Brightness.dark,
          surface: AppTheme.surfaceDark,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Data model
// ─────────────────────────────────────────────────────────────────────────────
class ChatMessage {
  final String text;
  final bool isUser;
  final String modelName;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.modelName = "",
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  HomeScreen
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _navIndex = 1;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final QuantSpaceApi _api = QuantSpaceApi();
  final ImagePicker _picker = ImagePicker();

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  String _selectedModelName = 'Gemini 1.5 Flash';
  String _selectedModelId = 'gemini/gemini-1.5-flash';

  // Input field focus animation
  late final AnimationController _inputFocusCtrl;
  late final Animation<double> _inputBorderOpacity;
  final FocusNode _inputFocus = FocusNode();

  // Send button press
  late final AnimationController _sendBtnCtrl;
  late final Animation<double> _sendBtnScale;

  // Empty state entrance
  late final AnimationController _emptyStateCtrl;
  late final Animation<double> _emptyStateOpacity;
  late final Animation<double> _emptyStateScale;

  final List<Map<String, String>> _aiModels = [
    {'name': 'Gemini 1.5 Flash', 'id': 'gemini/gemini-1.5-flash', 'icon': '✨'},
    {'name': 'GPT-4o', 'id': 'openai/gpt-4o', 'icon': '🧠'},
    {'name': 'Claude 3.5 Sonnet', 'id': 'openrouter/anthropic/claude-3.5-sonnet', 'icon': '🎭'},
    {'name': 'QuantCore 1.0', 'id': 'groq/llama-3.1-70b-versatile', 'icon': '⚡'},
    {'name': 'Llama 3.1 8B (Groq)', 'id': 'groq/llama-3.1-8b-instant', 'icon': '🚀'},
    {'name': 'Mixtral 8x7B (Groq)', 'id': 'groq/mixtral-8x7b-32768', 'icon': '🔥'},
    {'name': 'DeepSeek Chat', 'id': 'openrouter/deepseek/deepseek-chat', 'icon': '🤖'},
  ];

  @override
  void initState() {
    super.initState();

    // Input border glow on focus
    _inputFocusCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _inputBorderOpacity = CurvedAnimation(
      parent: _inputFocusCtrl,
      curve: Curves.easeOut,
    );
    _inputFocus.addListener(() {
      _inputFocus.hasFocus
          ? _inputFocusCtrl.forward()
          : _inputFocusCtrl.reverse();
    });

    // Send button scale
    _sendBtnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _sendBtnScale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _sendBtnCtrl, curve: Curves.easeInOut),
    );

    // Empty state fade + scale
    _emptyStateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _emptyStateOpacity =
        CurvedAnimation(parent: _emptyStateCtrl, curve: Curves.easeOut);
    _emptyStateScale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _emptyStateCtrl, curve: Curves.easeOutBack),
    );
    _emptyStateCtrl.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _inputFocusCtrl.dispose();
    _inputFocus.dispose();
    _sendBtnCtrl.dispose();
    _emptyStateCtrl.dispose();
    super.dispose();
  }

  // ── Tools ──────────────────────────────────────────────────────────────────
  void _showToolsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ToolsSheet(
        onWeather: () { _controller.text = "Tell me the current weather and forecast for my location."; },
        onQR: _startQRScanner,
        onImageSearch: _pickImageAndSearch,
        onAnalyze: _pickImageAndAnalyze,
        onGenImage: _pickPromptAndGenerateImage,
      ),
    );
  }

  void _startQRScanner() async {
    final status = await Permission.camera.request();
    if (!status.isGranted || !mounted) return;
    showDialog(
      context: context,
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text("Scan QR Code", style: GoogleFonts.outfit()),
          backgroundColor: AppTheme.backgroundBlack,
        ),
        body: MobileScanner(
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              _controller.text = "Analyze this data: ${barcodes.first.rawValue ?? ''}";
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  void _pickImageAndSearch() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _controller.text = "Search the web for details about this image...";
      _handleSend();
    }
  }

  void _pickImageAndAnalyze() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _controller.text = "Perform a multi-point technical analysis on this chart image.";
      _handleSend();
    }
  }

  void _pickPromptAndGenerateImage() {
    showDialog(
      context: context,
      builder: (context) {
        final promptController = TextEditingController();
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("AI Image Generator",
              style: GoogleFonts.outfit(color: AppTheme.primaryRed, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: promptController,
            style: GoogleFonts.outfit(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: "Enter an image description...",
              hintStyle: GoogleFonts.outfit(
                  color: AppTheme.textSecondary.withOpacity(0.4)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel",
                  style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final prompt = promptController.text.trim();
                Navigator.pop(context);
                if (prompt.isNotEmpty) {
                  _controller.text = "Generate a high-quality AI image: $prompt";
                  _handleSend();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("Generate", style: GoogleFonts.outfit()),
            ),
          ],
        );
      },
    );
  }

  // ── Send logic ─────────────────────────────────────────────────────────────
  void _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping) return;

    // Reset empty state animation for next time
    _emptyStateCtrl.reset();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      if (text.startsWith("Generate a high-quality AI image:")) {
        final prompt =
        text.replaceFirst("Generate a high-quality AI image:", "").trim();
        final imageUrl = await _api.generateImage(prompt);
        setState(() {
          _messages.add(ChatMessage(
            text: imageUrl != null && imageUrl.startsWith("http")
                ? "### Result:\n![Generated AI Image]($imageUrl)"
                : "Failed to generate image. Please try again.",
            isUser: false,
            modelName: "IMAGE ENGINE",
          ));
        });
      } else {
        final response = await _api.chat(text, model: _selectedModelId);
        setState(() {
          _messages.add(ChatMessage(
            text: response['content'],
            isUser: false,
            modelName: _selectedModelName,
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "🚨 **Error**: Connection failed. ${e.toString()}",
          isUser: false,
        ));
      });
    } finally {
      setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundBlack,
      appBar: _buildBlurredAppBar(),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(left: isDesktop ? 70 : 0),
            child: Stack(
              children: [
                _buildChatThread(),
                _buildFloatingInput(),
              ],
            ),
          ),
          Positioned(
            bottom: isDesktop ? null : 0,
            top: isDesktop ? 0 : null,
            left: 0,
            right: isDesktop ? null : 0,
            child: CustomAppBar(
              selectedIndex: _navIndex,
              onItemSelected: (index) => setState(() => _navIndex = index),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildBlurredAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: AppBar(
            backgroundColor: AppTheme.backgroundBlack.withOpacity(0.4),
            elevation: 0,
            title: Row(
              children: [
                Text(
                  "QuantCore",
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: AppTheme.primaryRed,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 16),
                _buildModelDropdown(),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded, color: Colors.white38),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded,
                    color: Colors.white24),
                onPressed: () {
                  setState(() => _messages.clear());
                  _api.resetSession();
                  // Re-trigger empty state entrance
                  _emptyStateCtrl.reset();
                  _emptyStateCtrl.forward();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedModelName,
          dropdownColor: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          icon: const Icon(Icons.unfold_more_rounded,
              size: 16, color: Colors.white38),
          items: _aiModels
              .map((m) => DropdownMenuItem(
            value: m['name'],
            child: Row(
              children: [
                Text(m['icon']!,
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  m['name']!,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ))
              .toList(),
          onChanged: (val) {
            setState(() {
              _selectedModelName = val!;
              _selectedModelId = _aiModels
                  .firstWhere((e) => e['name'] == val)['id']!;
            });
          },
        ),
      ),
    );
  }

  // ── Chat thread ────────────────────────────────────────────────────────────
  Widget _buildChatThread() {
    if (_messages.isEmpty) return _buildEmptyState();

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 100, bottom: 150),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) return _buildTypingIndicator();
        return _AnimatedMessageRow(
          message: _messages[index],
          index: index,
          getModelIcon: _getModelIcon,
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.012),
        border: Border(
            bottom:
            BorderSide(color: Colors.white.withOpacity(0.03), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar("⚡", AppTheme.primaryRed),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedModelName.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: Colors.white38,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                // Animated thinking dots
                _ThinkingDots(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _emptyStateOpacity,
      child: ScaleTransition(
        scale: _emptyStateScale,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing icon
              _PulsingIcon(),
              const SizedBox(height: 24),
              Text(
                "How can I help you today?",
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Powered by QuantCore.Ai Gateway",
                style: GoogleFonts.outfit(
                    color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _AnimatedButton(
                    label: "Sign In",
                    filled: true,
                    onTap: () => Navigator.push(
                      context,
                      _smoothRoute(const SignInScreen()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _AnimatedButton(
                    label: "Sign Up",
                    filled: false,
                    onTap: () => Navigator.push(
                      context,
                      _smoothRoute(const SignUpScreen()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getModelIcon(String name) {
    try {
      return _aiModels.firstWhere((m) => m['name'] == name)['icon'] ?? "⚡";
    } catch (_) {
      return "⚡";
    }
  }

  Widget _buildAvatar(String icon, Color color) {
    return Container(
      height: 34,
      width: 34,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(child: Text(icon, style: const TextStyle(fontSize: 14))),
    );
  }

  // ── Floating input ─────────────────────────────────────────────────────────
  Widget _buildFloatingInput() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundBlack.withOpacity(0),
              AppTheme.backgroundBlack.withOpacity(0.8),
              AppTheme.backgroundBlack,
              AppTheme.backgroundBlack,
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Center(
          child: AnimatedBuilder(
            animation: _inputBorderOpacity,
            builder: (_, child) {
              return Container(
                constraints: const BoxConstraints(maxWidth: 850),
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMedium,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Color.lerp(
                      Colors.white.withOpacity(0.08),
                      AppTheme.primaryRed.withOpacity(0.45),
                      _inputBorderOpacity.value,
                    )!,
                    width: 1.0 + _inputBorderOpacity.value * 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 40,
                      offset: const Offset(0, 15),
                    ),
                    BoxShadow(
                      color: AppTheme.primaryRed
                          .withOpacity(_inputBorderOpacity.value * 0.08),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.auto_awesome_mosaic_rounded,
                      color: Colors.white38, size: 22),
                  onPressed: _showToolsMenu,
                  tooltip: "Tools",
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _inputFocus,
                    style: GoogleFonts.outfit(
                        fontSize: 16, color: AppTheme.textPrimary),
                    maxLines: 5,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: "Ask anything to QuantCore...",
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                      hintStyle: GoogleFonts.outfit(
                          color: Colors.white24, fontSize: 16),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: _isTyping
                      ? const Padding(
                    key: ValueKey('loading'),
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                  )
                      : Padding(
                    key: const ValueKey('send'),
                    padding: const EdgeInsets.all(4.0),
                    child: ScaleTransition(
                      scale: _sendBtnScale,
                      child: GestureDetector(
                        onTapDown: (_) => _sendBtnCtrl.forward(),
                        onTapUp: (_) async {
                          await _sendBtnCtrl.reverse();
                          _handleSend();
                        },
                        onTapCancel: () => _sendBtnCtrl.reverse(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryRed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.send_rounded,
                              size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Animated message row — each new message slides + fades in
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedMessageRow extends StatefulWidget {
  final ChatMessage message;
  final int index;
  final String Function(String) getModelIcon;

  const _AnimatedMessageRow({
    required this.message,
    required this.index,
    required this.getModelIcon,
  });

  @override
  State<_AnimatedMessageRow> createState() => _AnimatedMessageRowState();
}

class _AnimatedMessageRowState extends State<_AnimatedMessageRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(widget.message.isUser ? 0.04 : -0.04, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            color: msg.isUser
                ? Colors.transparent
                : Colors.white.withOpacity(0.012),
            border: Border(
              bottom: BorderSide(
                  color: Colors.white.withOpacity(0.03), width: 1),
            ),
          ),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(
                    msg.isUser
                        ? "👤"
                        : widget.getModelIcon(msg.modelName),
                    msg.isUser ? Colors.blueGrey : AppTheme.primaryRed,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.isUser
                              ? "YOU"
                              : msg.modelName.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: Colors.white38,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        MarkdownBody(
                          data: msg.text,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: GoogleFonts.outfit(
                                fontSize: 16,
                                height: 1.6,
                                color: AppTheme.textPrimary),
                            h1: GoogleFonts.outfit(
                                color: AppTheme.primaryRed,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                            code: GoogleFonts.outfit(
                                backgroundColor:
                                const Color(0xFF1E1E1E),
                                color: Colors.orangeAccent,
                                fontSize: 14),
                            codeblockDecoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(12),
                              border:
                              Border.all(color: Colors.white10),
                            ),
                            blockquote: GoogleFonts.outfit(
                                color: Colors.white60,
                                fontStyle: FontStyle.italic),
                            blockquoteDecoration: const BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                    color: AppTheme.primaryRed,
                                    width: 4),
                              ),
                            ),
                            img: const TextStyle(fontSize: 0),
                          ),
                          imageBuilder: (uri, title, alt) =>
                              _buildGeneratedImage(uri.toString()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String icon, Color color) {
    return Container(
      height: 34,
      width: 34,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(
          child: Text(icon, style: const TextStyle(fontSize: 14))),
    );
  }

  Widget _buildGeneratedImage(String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 300,
                  width: double.infinity,
                  color: Colors.white.withOpacity(0.05),
                  child: const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryRed),
                  ),
                );
              },
              errorBuilder: (context, error, _) => Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image_rounded,
                        color: Colors.white24, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      "Image load blocked by provider",
                      style: GoogleFonts.outfit(
                          color: Colors.white38, fontSize: 12),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.open_in_new_rounded,
                          size: 14, color: AppTheme.primaryRed),
                      label: Text("Open in Browser",
                          style: GoogleFonts.outfit(
                              color: AppTheme.primaryRed)),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "GEN AI",
                  style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Thinking dots (typing indicator)
// ─────────────────────────────────────────────────────────────────────────────
class _ThinkingDots extends StatefulWidget {
  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _scales;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
          (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _scales = _ctrls
        .map((c) => Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: c, curve: Curves.easeInOut),
    ))
        .toList();

    // Stagger each dot
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) _ctrls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        return ScaleTransition(
          scale: _scales[i],
          child: Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: Colors.white38,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Pulsing icon for empty state
// ─────────────────────────────────────────────────────────────────────────────
class _PulsingIcon extends StatefulWidget {
  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _glow = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) => Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          color: AppTheme.primaryRed.withOpacity(0.10),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.primaryRed
                .withOpacity(0.15 + _glow.value * 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color:
              AppTheme.primaryRed.withOpacity(_glow.value * 0.18),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Center(
            child: Text("⚡", style: TextStyle(fontSize: 40))),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Animated press button
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedButton extends StatefulWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _AnimatedButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) async {
        await _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.filled
            ? Container(
          padding: const EdgeInsets.symmetric(
              vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            color: AppTheme.primaryRed,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white),
          ),
        )
            : Container(
          padding: const EdgeInsets.symmetric(
              vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.5),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tools bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _ToolsSheet extends StatefulWidget {
  final VoidCallback onWeather;
  final VoidCallback onQR;
  final VoidCallback onImageSearch;
  final VoidCallback onAnalyze;
  final VoidCallback onGenImage;

  const _ToolsSheet({
    required this.onWeather,
    required this.onQR,
    required this.onImageSearch,
    required this.onAnalyze,
    required this.onGenImage,
  });

  @override
  State<_ToolsSheet> createState() => _ToolsSheetState();
}

class _ToolsSheetState extends State<_ToolsSheet>
    with TickerProviderStateMixin {
  late final List<AnimationController> _itemCtrls;
  late final List<Animation<double>> _itemOpacities;
  late final List<Animation<Offset>> _itemSlides;

  static const _items = [
    (Icons.wb_sunny_rounded, "Check Weather", "Get real-time weather & forecast"),
    (Icons.qr_code_scanner_rounded, "Scan QR Code", "Analyze data from QR codes"),
    (Icons.image_search_rounded, "Search by Image", "Ask about a photo from gallery"),
    (Icons.analytics_rounded, "Analyze Chart", "Perform technical chart analysis"),
    (Icons.brush_rounded, "Generate AI Image", "Create unique images using free AI"),
  ];

  @override
  void initState() {
    super.initState();
    _itemCtrls = List.generate(
      _items.length,
          (i) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 350)),
    );
    _itemOpacities = _itemCtrls
        .map((c) =>
        CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();
    _itemSlides = _itemCtrls
        .map((c) => Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOutCubic)))
        .toList();

    for (int i = 0; i < _itemCtrls.length; i++) {
      Future.delayed(Duration(milliseconds: 60 * i), () {
        if (mounted) _itemCtrls[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _itemCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTap(int index) {
    Navigator.pop(context);
    [
      widget.onWeather,
      widget.onQR,
      widget.onImageSearch,
      widget.onAnalyze,
      widget.onGenImage,
    ][index]();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(32)),
        border:
        Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 40,
              spreadRadius: 10),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Tools & Actions",
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          ...List.generate(_items.length, (i) {
            final (icon, title, subtitle) = _items[i];
            return FadeTransition(
              opacity: _itemOpacities[i],
              child: SlideTransition(
                position: _itemSlides[i],
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                      AppTheme.primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon,
                        color: AppTheme.primaryRed, size: 22),
                  ),
                  title: Text(title,
                      style: GoogleFonts.outfit(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600)),
                  subtitle: Text(subtitle,
                      style: GoogleFonts.outfit(
                          color: AppTheme.textSecondary,
                          fontSize: 12)),
                  onTap: () => _onTap(i),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Smooth page route helper
// ─────────────────────────────────────────────────────────────────────────────
PageRouteBuilder _smoothRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) => FadeTransition(
      opacity:
      CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  );
}