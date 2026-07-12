// lib/screens/signin_screen.dart
import 'dart:math' as math; // Needed for animations
import 'dart:ui'; // For ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // For MouseRegion and TapGestureRecognizer
import 'package:flutter/scheduler.dart'; // For Future.delayed

// Assuming these are your custom theme and screen files.
// Replace 'package:your_project_name/' with your actual project path.
import 'package:QuantMessage_Application/core/app_theme.dart'; // Your custom theme file
import 'package:QuantMessage_Application/screens/signup_screen.dart'; // Your Signup Screen
import 'package:QuantMessage_Application/screens/home_screen.dart'; // Your Home Screen

/// --- Custom Animations & Widgets (Included directly for ease of use) ---
/// If these are in separate files, ensure you have the correct import paths.

// --- Modern Logo Widget ---
class _ModernLogo extends StatelessWidget {
  const _ModernLogo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppTheme.primaryRed.withOpacity(0.1), // Using primaryRed from theme
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryRed.withOpacity(0.3), // Using primaryRed from theme
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRed.withOpacity(0.2), // Using primaryRed from theme
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: const Icon(
        Icons.smart_toy_rounded, // Or a QuantSync specific icon
        size: 32,
        color: AppTheme.primaryRed, // Using primaryRed from theme
      ),
    );
  }
}

// --- Slide/Fade In Animation Utility ---
class SlideFadeTransition extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Offset offset;

  const SlideFadeTransition({
    super.key,
    required this.child,
    required this.delay,
    this.offset = const Offset(0, 30),
  });

  @override
  State<SlideFadeTransition> createState() => _SlideFadeTransitionState();
}

class _SlideFadeTransitionState extends State<SlideFadeTransition> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: widget.offset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Use Future.delayed to trigger animation after a specified delay
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// --- SignInScreen Implementation ---
/// Combines modern glassmorphism, subtle animations, and clear UI elements.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Dummy user data for demonstration
  final Map<String, String> _validUsers = {
    'user@example.com': 'password123',
    'admin@quant-sync.com': 'admin123', // Updated email domain
  };

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate API call or authentication process
    await Future.delayed(const Duration(seconds: 2)); // Simulate network latency

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    // Simulate user verification
    if (_validUsers.containsKey(email) && _validUsers[email] == password) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Welcome back!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.green.shade700, // Success color
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        // Navigate to Home Screen upon successful sign-in
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Invalid email or password. Please try again.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.red.shade700, // Error color
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false); // Stop loading indicator
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack, // Dark background from theme
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            // ConstrainedBox to limit the maximum width of content on larger screens
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Animated Logo ---
                    const SlideFadeTransition(
                      delay: Duration(milliseconds: 100),
                      offset: Offset(0, 20), // Subtle slide up
                      child: Center(
                        child: _ModernLogo(),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- Animated Title ---
                    const SlideFadeTransition(
                      delay: Duration(milliseconds: 200),
                      offset: Offset(0, 25), // Subtle slide up
                      child: Text(
                        'Welcome back',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700, // Bolder weight
                          color: AppTheme.textPrimary, // Primary text color from theme
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // --- Animated Subtitle ---
                    const SlideFadeTransition(
                      delay: Duration(milliseconds: 300),
                      offset: Offset(0, 30), // Subtle slide up
                      child: Text(
                        'Sign in to continue to QuantSync', // Replaced 'Q.Ai'
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.textSecondary, // Secondary text color from theme
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // --- Modern "Glass/Subtle" Form Card ---
                    SlideFadeTransition(
                      delay: const Duration(milliseconds: 400),
                      offset: Offset(0, 35), // Subtle slide up
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark.withOpacity(0.5), // Dark surface with transparency
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08), // Subtle border
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // --- Email Field ---
                            _buildModernTextField(
                              controller: _emailController,
                              label: 'Email',
                              hint: 'you@quant-sync.com', // Updated hint
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Enter your email';
                                // Basic email format validation
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // --- Password Field ---
                            _buildModernTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: '••••••••',
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              isPassword: true,
                              onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Enter your password';
                                // You can add more password validation rules here (e.g., min length)
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),

                            // --- Forgot Password Link ---
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  // TODO: Implement Forgot Password Navigation/Logic
                                  print('Forgot Password tapped');
                                },
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: AppTheme.primaryRed, // Red color from theme
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // --- Modern Sign In Button ---
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signIn, // Disable button while loading
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryRed, // Red button from theme
                                  foregroundColor: Colors.white, // Text color
                                  elevation: 0, // No shadow on button itself
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: _isLoading
                                    ? const SizedBox( // Loading indicator
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                                    : const Text( // Button text
                                  'Sign in',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- Navigation to Sign Up ---
                    const SlideFadeTransition(
                      delay: Duration(milliseconds: 500),
                      offset: Offset(0, 40), // Subtle slide up
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 8),
                          // Sign Up Link with TapGestureRecognizer
                          _SignUpLink(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Helper method to build modern text fields with glassmorphism effect and animations.
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
        // Label above the text field
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Transparent background with blur effect for input fields
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.4), fontSize: 15),
                prefixIcon: Icon(icon, color: AppTheme.textSecondary.withOpacity(0.7), size: 20),
                suffixIcon: isPassword
                    ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppTheme.textSecondary.withOpacity(0.7),
                    size: 20,
                  ),
                  onPressed: onTogglePassword,
                )
                    : null,
                filled: true,
                fillColor: AppTheme.surfaceMedium.withOpacity(0.3), // Slightly lighter surface
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder( // Default border
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.04)),
                ),
                enabledBorder: OutlineInputBorder( // Border when enabled but not focused
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder( // Border when focused
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryRed, width: 1.5), // Focus highlight
                ),
                errorBorder: OutlineInputBorder( // Border when there's an error
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.5), width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder( // Border when error and focused
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 1),
                ),
              ),
              validator: validator,
            ),
          ),
        ),
      ],
    );
  }
}


/// Inline Widget for the Sign Up link to handle tap and styling.
class _SignUpLink extends StatelessWidget {
  const _SignUpLink({super.key});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // Navigate to Sign Up Screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SignUpScreen()),
          );
        },
        child: const Text(
          'Sign up',
          style: TextStyle(
            color: AppTheme.primaryRed, // Use primary Red for link consistency
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}