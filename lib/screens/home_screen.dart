import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // INTEGRATED: For Auth checks

import '../core/app_theme.dart';
import 'app_bar.dart';
import 'chat_screen.dart';
import 'history_screen.dart';
import 'incogonito_screen.dart';
import 'signin_screen.dart';
import 'signup_screen.dart';
import 'settings_screen.dart'; // INTEGRATED: Now includes showSettingsPopup

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _previousIndex = 0;

  // We use a getter for pages so they can be rebuilt if the auth state changes
  List<Widget> get _pages => [
    DashboardTab(onStartChat: () => _onItemSelected(1)),
    const ChatScreen(),
    const IncognitoScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  void _onItemSelected(int index) {
    if (index == _currentIndex) return;

    // ──────────────────────────────────────────────────────────────────────────
    // AUTH GUARD: Protect sensitive tabs (Chat, History)
    // ──────────────────────────────────────────────────────────────────────────
    if (index == 1 || index == 3) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        // User is not logged in, redirect to Sign In instead of switching tab
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
        );
        return; // Stop the tab switch
      }
    }

    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.black,
      body: isDesktop
          ? Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 70),
              child: _AnimatedPageSwitcher(
                currentIndex: _currentIndex,
                pages: _pages,
              ),
            ),
          ),
          CustomAppBar(
            selectedIndex: _currentIndex,
            onItemSelected: _onItemSelected,
          ),
        ],
      )
          : Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 70),
              child: _AnimatedPageSwitcher(
                currentIndex: _currentIndex,
                pages: _pages,
              ),
            ),
          ),
          CustomAppBar(
            selectedIndex: _currentIndex,
            onItemSelected: _onItemSelected,
          ),
        ],
      ),
    );
  }
}

class _AnimatedPageSwitcher extends StatelessWidget {
  final int currentIndex;
  final List<Widget> pages;

  const _AnimatedPageSwitcher({
    required this.currentIndex,
    required this.pages,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(currentIndex),
        child: pages[currentIndex],
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  final VoidCallback onStartChat;

  const DashboardTab({super.key, required this.onStartChat});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _particleCtrl;
  late final AnimationController _btnCtrl;
  late final Animation<double> _btnScale;

  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _gridOpacity;
  late final Animation<double> _gridScale;
  late final Animation<double> _btnOpacity;
  late final Animation<Offset> _btnSlide;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _titleOpacity = CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.0, 0.25, curve: Curves.easeOut));
    _titleSlide = Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.0, 0.30, curve: Curves.easeOutCubic)),
    );

    _subtitleOpacity = CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.08, 0.35, curve: Curves.easeOut));
    _subtitleSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.08, 0.38, curve: Curves.easeOutCubic)),
    );

    _gridOpacity = CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.16, 0.65, curve: Curves.easeOut));
    _gridScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.16, 0.65, curve: Curves.easeOutBack)),
    );

    _btnOpacity = CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.42, 1.0, curve: Curves.easeOut));
    _btnSlide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: const Interval(0.42, 1.0, curve: Curves.easeOutCubic)),
    );

    _entranceCtrl.forward();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3800))..repeat(reverse: true);
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 8000))..repeat();
    _btnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120), lowerBound: 0.0, upperBound: 1.0);
    _btnScale = Tween<double>(begin: 1.0, end: 0.94).animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    _particleCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              final t = _pulseCtrl.value;
              return Stack(
                children: [
                  Positioned(top: -120 + t * 20, left: -120 + t * 10, child: _buildRadialGlow(Colors.blue.withOpacity(0.08 + t * 0.06), 320 + t * 40)),
                  Positioned(bottom: -120 + t * 20, right: -120 + t * 10, child: _buildRadialGlow(Colors.purple.withOpacity(0.08 + t * 0.06), 320 + t * 40)),
                  Positioned(top: MediaQuery.of(context).size.height * 0.4, left: MediaQuery.of(context).size.width * 0.3, child: _buildRadialGlow(Colors.indigo.withOpacity(0.04 + t * 0.03), 180)),
                ],
              );
            },
          ),
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (context, _) => CustomPaint(
              painter: _ParticlePainter(_particleCtrl.value),
              size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _titleOpacity,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: _ShimmerText(
                        controller: _shimmerCtrl,
                        text: "< Welcome to QUANTMESSAGE >",
                        style: GoogleFonts.tinos(
                          fontSize: 45,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _subtitleOpacity,
                    child: SlideTransition(
                      position: _subtitleSlide,
                      child: Text("< Messaging in Modern Era >", style: GoogleFonts.jetBrainsMono(fontSize: 16, color: Colors.white.withOpacity(0.45), letterSpacing: 4, fontWeight: FontWeight.w300)),
                    ),
                  ),
                  const SizedBox(height: 60),
                  FadeTransition(
                    opacity: _gridOpacity,
                    child: ScaleTransition(scale: _gridScale, child: _FeatureGrid()),
                  ),
                  const SizedBox(height: 60),
                  FadeTransition(
                    opacity: _btnOpacity,
                    child: SlideTransition(
                      position: _btnSlide,
                      child: Column(
                        children: [
                          _LaunchChatButton(
                            btnCtrl: _btnCtrl,
                            btnScale: _btnScale,
                            onTap: widget.onStartChat,
                          ),
                          const SizedBox(height: 15),
                          _ContinueButton(btnCtrl: _btnCtrl, btnScale: _btnScale),
                          const SizedBox(height: 15),
                          _SettingsButton(btnCtrl: _btnCtrl, btnScale: _btnScale),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadialGlow(Color color, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent])),
    );
  }
}


class _LaunchChatButton extends StatelessWidget {
  final AnimationController btnCtrl;
  final Animation<double> btnScale;
  final VoidCallback onTap;
  const _LaunchChatButton({required this.btnCtrl, required this.btnScale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => btnCtrl.forward(),
      onTapUp: (_) async {
        await btnCtrl.reverse();
        onTap();
      },
      onTapCancel: () => btnCtrl.reverse(),
      child: ScaleTransition(
        scale: btnScale,
        child: Container(
          width: 220, height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF257BFA)]),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Center(
            child: Text(" < USE >", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

class _ShimmerText extends AnimatedWidget {
  final String text;
  final TextStyle style;
  const _ShimmerText({required AnimationController controller, required this.text, required this.style}) : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    final t = (listenable as AnimationController).value;
    final shimmerOffset = t * 3.0 - 1.0;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment(-1.5 + shimmerOffset * 2, 0),
        end: Alignment(0.5 + shimmerOffset * 2, 0),
        colors: const [Color(0xFFFFFFFF), Color(0xFFCCCCCC), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFFE8E8FF), Color(0xFFFFFFFF)],
        stops: const [0.0, 0.35, 0.48, 0.52, 0.65, 1.0],
      ).createShader(bounds),
      child: Text(text, textAlign: TextAlign.center, style: style),
    );
  }
}

class _FeatureGrid extends StatefulWidget {
  @override
  State<_FeatureGrid> createState() => _FeatureGridState();
}

class _FeatureGridState extends State<_FeatureGrid> with TickerProviderStateMixin {
  static const _cards = [
    (Icons.auto_awesome, "AI Driven", "Cognitive reasoning for every message."),
    (Icons.lock_outline, "Ultra Private", "End-to-end encryption by default."),
    (Icons.bolt, "Quantum Speed", "Instant delivery across the globe."),
    (Icons.blur_on, "Low Latency", "QuantMessage Welcomes You "),
  ];

  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _opacities;
  late final List<Animation<Offset>> _slides;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(_cards.length, (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 500)));
    _opacities = _ctrls.map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut)).toList();
    _slides = _ctrls.map((c) => Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic))).toList();
    for (int i = 0; i < _ctrls.length; i++) {
      Future.delayed(Duration(milliseconds: 80 * i), () { if (mounted) _ctrls[i].forward(); });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20, runSpacing: 20, alignment: WrapAlignment.center,
      children: List.generate(_cards.length, (i) {
        final (icon, title, desc) = _cards[i];
        return FadeTransition(
          opacity: _opacities[i],
          child: SlideTransition(position: _slides[i], child: _GlassCard(icon: icon, title: title, desc: desc)),
        );
      }),
    );
  }
}

class _GlassCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _GlassCard({required this.icon, required this.title, required this.desc});

  @override
  State<_GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<_GlassCard> with SingleTickerProviderStateMixin {
  late final AnimationController _hoverCtrl;
  late final Animation<double> _glow;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _glow = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _hoverCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _hoverCtrl.forward(),
      onExit: (_) => _hoverCtrl.reverse(),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedBuilder(
          animation: _hoverCtrl,
          builder: (_, __) {
            final t = _glow.value;
            return AnimatedScale(
              scale: _pressed ? 0.96 : 1.0,
              duration: const Duration(milliseconds: 140),
              child: SizedBox(
                width: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05 + t * 0.04),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.10 + t * 0.14)),
                      ),
                      child: Column(
                        children: [
                          Icon(widget.icon, color: Colors.white, size: 30),
                          const SizedBox(height: 15),
                          Text(widget.title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text(widget.desc, textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final AnimationController btnCtrl;
  final Animation<double> btnScale;
  const _ContinueButton({required this.btnCtrl, required this.btnScale});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => btnCtrl.forward(),
      onTapUp: (_) async {
        await btnCtrl.reverse();
        Navigator.push(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const SignInScreen(), transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child)));
      },
      onTapCancel: () => btnCtrl.reverse(),
      child: ScaleTransition(
        scale: btnScale,
        child: Container(
          width: 220, height: 60,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: Center(child: Text("Continue", style: GoogleFonts.outfit(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final AnimationController btnCtrl;
  final Animation<double> btnScale;
  const _SettingsButton({required this.btnCtrl, required this.btnScale});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => btnCtrl.forward(),
      onTapUp: (_) async {
        await btnCtrl.reverse();
        // INTEGRATED: Call the popup directly instead of pushing a route
        showSettingsPopup(context);
      },
      onTapCancel: () => btnCtrl.reverse(),
      child: ScaleTransition(
        scale: btnScale,
        child: Container(
          width: 220, height: 60,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.2))),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text("App Settings", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter(this.progress);

  static final List<_Particle> _particles = List.generate(28, (i) {
    final r = math.Random(i * 31 + 7);
    return _Particle(x: r.nextDouble(), y: r.nextDouble(), size: 0.8 + r.nextDouble() * 1.8, speed: 0.06 + r.nextDouble() * 0.10, phase: r.nextDouble() * math.pi * 2, drift: (r.nextDouble() - 0.5) * 0.015);
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final y = ((p.y - p.speed * progress + 1.0) % 1.0);
      final x = p.x + math.sin(progress * math.pi * 2 + p.phase) * p.drift;
      final opacity = (math.sin(progress * math.pi * 2 * 0.4 + p.phase) * 0.5 + 0.5).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(x * size.width, y * size.height), p.size, Paint()..color = Colors.white.withOpacity(opacity * 0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => oldDelegate.progress != progress;
}

class _Particle {
  final double x, y, size, speed, phase, drift;
  const _Particle({required this.x, required this.y, required this.size, required this.speed, required this.phase, required this.drift});
}
