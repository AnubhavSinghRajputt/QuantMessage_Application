import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

import '../core/app_theme.dart';
import '../core/chat_message.dart';
import '../core/config.dart' as app_config; // FIXED: Alias to avoid name conflict
import '../services/quant_space_api.dart';
import 'animations/animation_effects/connectors_animation.dart'; // FIXED: Corrected import path
import 'signin_screen.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  final QuantSpaceApi _api = QuantSpaceApi();

  bool _isLoading = false;
  bool _obscurePassword = true;

  late final AnimationController _cardAnimCtrl;
  late final Animation<double> _cardScale;
  late final Animation<double> _cardOpacity;

  @override
  void initState() {
    super.initState();
    _cardAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _cardScale = CurvedAnimation(parent: _cardAnimCtrl, curve: Curves.easeOutBack);
    _cardOpacity = CurvedAnimation(parent: _cardAnimCtrl, curve: Curves.easeOut);
    _cardAnimCtrl.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _cardAnimCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  INTEGRATED: Real Supabase Signup + Config Integration
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. Create the user in Supabase Auth
      final response = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'full_name': _nameController.text.trim(),
        },
      );

      if (response.user != null) {
        // 2. Trigger the profile creation automatically via our SQL trigger
        // The 'handle_new_user' function in Supabase takes care of inserting into 'profiles'

        // 3. Send a welcome message to the AI (Optional, but keeps the system in sync)
        // We use the model defined in Config
        final welcomeModel = app_config.Config.models[0];
        await _api.getAIResponse(
            "Hello AI, I just created an account using ${welcomeModel.name}.",
            response.user!.id
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Account created! Welcome aboard.', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green.shade800,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade800),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade800),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: Stack(
        children: [
          // 1. Background image/gradient that gets blurred
          _buildBlurredBackground(),

          // 2. The modern split-screen layout
          LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 800;

              if (isMobile) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Mobile: Show the animation at the top
                      const SizedBox(
                          height: 250,
                          child: ConnectorsAnimation()
                      ),
                      _buildSignupCard(),
                    ],
                  ),
                );
              }

              return Row(
                children: [
                  // LEFT SIDE: Hero / Branding Area
                  Expanded(
                    flex: 5,
                    child: _buildLeftHeroPanel(),
                  ),
                  // RIGHT SIDE: The Card Style Signup Form
                  Expanded(
                    flex: 4,
                    child: _buildRightSignupPanel(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // 1. Background with a slight color and an image overlay
  Widget _buildBlurredBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.5, -0.5),
          radius: 1.5,
          colors: [Color(0xFF2A0A0A), AppTheme.backgroundBlack],
        ),
      ),
      child: Stack(
        children: [
          // The actual image that will be blurred
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.network(
                'https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=1500&q=80',
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: AppTheme.backgroundBlack),
              ),
            ),
          ),
          // The Blur Effect applied to the whole background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),
        ],
      ),
    );
  }

  // 2. The Left Side: Big Branding & Visuals
  Widget _buildLeftHeroPanel() {
    return Container(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ──────────────────────────────────────────────────────────
          // INTEGRATED: Connectors Animation at the top-left
          // Wrapped in a glowing green border to make it pop.
          // ──────────────────────────────────────────────────────────
          FadeInLeft(
            duration: const Duration(milliseconds: 1000),
            child: Container(
              height: 230,
              width: 430,
              padding: const EdgeInsets.all(6), // Padding for the border thickness
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFF22C55E).withOpacity(0.7), // Shining green border
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withOpacity(0.3), // Green glow shadow
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                // The imported widget fits naturally here
                child: const ConnectorsAnimation(),
              ),
            ),
          ),
          const SizedBox(height: 32),

          FadeInLeft(
            delay: const Duration(milliseconds: 300),
            duration: const Duration(milliseconds: 1000),
            child: Text(
              "The Future of\nIntelligent Messaging.",
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -1.0),
            ),
          ),
          const SizedBox(height: 16),
          FadeInLeft(
            delay: const Duration(milliseconds: 600),
            duration: const Duration(milliseconds: 1000),
            child: Text(
              "Create your account and unlock the full power of our multi-agent AI ecosystem.",
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16, height: 1.5, fontWeight: FontWeight.w300),
            ),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            delay: const Duration(milliseconds: 900),
            duration: const Duration(milliseconds: 1000),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildFeatureChip(Icons.shield_outlined, "End-to-End Encrypted"),
                _buildFeatureChip(Icons.bolt_rounded, "Quantum Speed"),
                _buildFeatureChip(Icons.psychology_outlined, "Multi-Agent AI"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryRed, size: 14),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // 3. The Right Side: The Glassmorphism Card
  Widget _buildRightSignupPanel() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: AnimatedBuilder(
          animation: _cardAnimCtrl,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.8 + (_cardScale.value * 0.2),
              child: Opacity(
                opacity: _cardOpacity.value,
                child: child,
              ),
            );
          },
          child: _buildSignupCard(),
        ),
      ),
    );
  }

  Widget _buildSignupCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(
              child: _ModernLogo(),
            ),
            const SizedBox(height: 32),
            Text(
              'Create Account',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Join Q.Ai and start exploring today',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 36),
            _buildModernTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'John Doe',
              icon: Icons.person_outline,
              keyboardType: TextInputType.name,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter your full name';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildModernTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'you@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter your email';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Enter valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildModernTextField(
              controller: _passwordController,
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              isPassword: true,
              onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter a password';
                if (value.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : Text('Create Account', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Already have an account?", style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14)),
                const SizedBox(width: 8),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const SignInScreen())),
                    child: Text('Sign in', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    bool isPassword = false,
    TextInputType? keyboardType,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: AppTheme.textSecondary.withOpacity(0.4), fontSize: 15),
            prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary, size: 20),
              onPressed: onTogglePassword,
            )
                : null,
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.04)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryRed, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.5), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

// Custom modern logo widget
class _ModernLogo extends StatelessWidget {
  const _ModernLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppTheme.primaryRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryRed.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: const Icon(Icons.smart_toy_rounded, size: 32, color: AppTheme.primaryRed),
    );
  }
}
