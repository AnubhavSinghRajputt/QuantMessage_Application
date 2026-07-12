// lib/screens/animations/animation_effects/connectors_animation.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ============================================================
/// ConnectorsAnimation
/// ============================================================
/// Recreates a workflow / agent-graph style diagram:
///   Start -> Detect User Intention -> (Technical Agent,
///                                       Agent 1,
///                                       Agent 2)
/// on a dark dotted-grid canvas with glowing neon-style
/// connectors, gradient node cards with colored glow shadows,
/// a rotating loader badge, and pulsing check badges - designed
/// to look lively and eye-catching.
///
/// HOW TO USE ON ANOTHER SCREEN:
/// -----------------------------------------------------------
/// 1. Copy this file into your project (e.g. lib/widgets/).
/// 2. Import it wherever you want to show the diagram:
///
///      import 'connectors_animation.dart';
///
/// 3. Drop it into your widget tree. It automatically scales
///    to fill the width available to it while keeping its
///    aspect ratio, so it works inside a Column, a Card, a
///    full screen body, etc:
///
///      SizedBox(
///        height: 320,
///        child: ConnectorsAnimation(),
///      )
///
///    or simply:
///
///      Expanded(child: ConnectorsAnimation())
/// ============================================================

class ConnectorsAnimation extends StatefulWidget {
  const ConnectorsAnimation({Key? key}) : super(key: key);

  @override
  State<ConnectorsAnimation> createState() => _ConnectorsAnimationState();
}

class _ConnectorsAnimationState extends State<ConnectorsAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const double _designWidth = 820;
  static const double _designHeight = 440;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: _designWidth / _designHeight,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: _designWidth,
            height: _designHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.2, -0.3),
                    radius: 1.2,
                    colors: [Color(0xFF141420), Color(0xFF08080C)],
                  ),
                ),
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: CustomPaint(painter: _DotGridPainter()),
                    ),
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) => CustomPaint(
                          painter: _ConnectorPainter(_controller.value),
                        ),
                      ),
                    ),
                    _startNode(),
                    _detectNode(),
                    _agentCard(
                      rect: _Layout.technical,
                      title: 'Technical Agent',
                      pills: const [
                        _Pill(label: 'gemini-2.0-flash', icon: Icons.auto_awesome, tint: Color(0xFF60A5FA)),
                      ],
                      glowColor: const Color(0xFF22D3EE),
                      badge: _checkBadge(),
                    ),
                    _agentCard(
                      rect: _Layout.agent1,
                      title: 'Agent 1',
                      pills: const [
                        _Pill(label: 'claude-3-7-sonnet-latest', icon: Icons.change_history, tint: Color(0xFFF59E0B)),
                        _Pill(label: '', icon: Icons.public, tint: Color(0xFF60A5FA)),
                      ],
                      glowColor: const Color(0xFF22D3EE),
                    ),
                    _agentCard(
                      rect: _Layout.agent2,
                      title: 'Agent 2',
                      pills: const [
                        _Pill(label: 'gpt-4o-mini', icon: Icons.blur_circular, tint: Color(0xFFA78BFA)),
                      ],
                      borderColor: const Color(0xFF22D3EE),
                      glowColor: const Color(0xFF22D3EE),
                      isActive: true,
                      badge: _spinnerBadge(),
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

  // -----------------------------------------------------------
  // Nodes
  // -----------------------------------------------------------

  Widget _startNode() {
    final r = _Layout.start;
    return Positioned(
      left: r.left,
      top: r.top,
      width: r.width,
      height: r.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1C6B3D), Color(0xFF0E3A20)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22C55E).withOpacity(0.35),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _iconAvatar(
                  icon: Icons.play_arrow,
                  colors: const [Color(0xFF4ADE80), Color(0xFF16A34A)],
                ),
                const SizedBox(width: 10),
                const Text(
                  'Start',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Positioned(top: -8, right: -8, child: _checkBadge()),
        ],
      ),
    );
  }

  Widget _detectNode() {
    final r = _Layout.detect;
    return Positioned(
      left: r.left,
      top: r.top,
      width: r.width,
      height: r.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4A1628), Color(0xFF28091A)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEC4899).withOpacity(0.28),
                  blurRadius: 26,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _iconAvatar(
                  icon: Icons.alt_route,
                  colors: const [Color(0xFFF472B6), Color(0xFFDB2777)],
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detect User Intention',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(height: 1, color: Colors.white.withOpacity(0.08)),
                      const SizedBox(height: 8),
                      _pillWidget(const _Pill(label: 'gpt-4.1', icon: Icons.change_history, tint: Color(0xFF34D399))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(top: -8, right: -8, child: _checkBadge()),
        ],
      ),
    );
  }

  Widget _agentCard({
    required Rect rect,
    required String title,
    required List<_Pill> pills,
    Color borderColor = Colors.transparent,
    Color glowColor = const Color(0xFF22D3EE),
    bool isActive = false,
    Widget? badge,
  }) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (isActive)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final pulse = 0.35 + 0.25 * math.sin(_controller.value * 2 * math.pi);
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withOpacity(pulse),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                );
              },
            ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF12393B), Color(0xFF06201F)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: borderColor == Colors.transparent ? 0 : 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withOpacity(0.18),
                  blurRadius: 18,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _iconAvatar(
                  icon: Icons.smart_toy,
                  colors: const [Color(0xFF67E8F9), Color(0xFF0EA5B7)],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...pills.map(
                            (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _pillWidget(p),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (badge != null) Positioned(top: -8, right: -8, child: badge),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // Small reusable pieces
  // -----------------------------------------------------------

  Widget _iconAvatar({required IconData icon, required List<Color> colors, double size = 34}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: colors.last.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.55),
    );
  }

  Widget _pillWidget(_Pill p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: p.tint.withOpacity(0.25), shape: BoxShape.circle),
            child: Icon(p.icon, size: 9, color: p.tint),
          ),
          if (p.label.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(p.label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Widget _checkBadge() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pulse = 1.0 + 0.1 * math.sin(_controller.value * 2 * math.pi);
        return Transform.scale(
          scale: pulse,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.6), blurRadius: 8, spreadRadius: 1),
              ],
            ),
            child: const Icon(Icons.check, size: 14, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _spinnerBadge() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi * 4,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.6), blurRadius: 8, spreadRadius: 1),
              ],
            ),
            child: const Icon(Icons.autorenew, size: 14, color: Colors.white),
          ),
        );
      },
    );
  }
}

/// A small model/tool badge shown inside a node card, e.g. the
/// model name pill ("gpt-4.1") or a bare icon pill.
class _Pill {
  final String label;
  final IconData icon;
  final Color tint;

  const _Pill({required this.label, this.icon = Icons.circle, this.tint = Colors.white});
}

/// Fixed design-space coordinates for every node, shared between
/// the node widgets and the connector painter so lines always
/// line up with the cards exactly.
class _Layout {
  static final Rect start = Rect.fromLTWH(28, 195, 150, 68);
  static final Rect detect = Rect.fromLTWH(205, 165, 270, 130);
  static final Rect technical = Rect.fromLTWH(520, 45, 280, 95);
  static final Rect agent1 = Rect.fromLTWH(520, 163, 280, 130);
  static final Rect agent2 = Rect.fromLTWH(520, 308, 280, 95);

  static Offset rightMid(Rect r) => Offset(r.right, r.center.dy);
  static Offset leftMid(Rect r) => Offset(r.left, r.center.dy);

  static Offset detectPort(int index) {
    switch (index) {
      case 0:
        return Offset(detect.right, detect.top + 20);
      case 1:
        return Offset(detect.right, detect.center.dy);
      default:
        return Offset(detect.right, detect.bottom - 20);
    }
  }
}

/// Draws the dotted background grid with a subtle circuit-board feel:
/// most dots are faint, every few dots along the grid are brighter.
class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final faint = Paint()..color = Colors.white.withOpacity(0.05);
    final bright = Paint()..color = const Color(0xFF60A5FA).withOpacity(0.10);
    const spacing = 18.0;
    int row = 0;
    for (double y = 8; y < size.height; y += spacing) {
      int col = 0;
      for (double x = 8; x < size.width; x += spacing) {
        final isBright = (row % 5 == 0) && (col % 5 == 0);
        canvas.drawCircle(Offset(x, y), isBright ? 1.6 : 1.1, isBright ? bright : faint);
        col++;
      }
      row++;
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) => false;
}

/// Draws the curved connectors between nodes as glowing neon-style
/// lines: a soft blurred glow pass plus a crisp core line, small
/// plug-style port markers at each end, branch index labels, and a
/// stream of glowing dots that continuously travels along each
/// connector to give the diagram a "live" running look.
class _ConnectorPainter extends CustomPainter {
  final double progress;

  const _ConnectorPainter(this.progress);

  static const Color lineColor = Color(0xFFE85D9E);
  static const Color lineColor2 = Color(0xFFA855F7);

  @override
  void paint(Canvas canvas, Size size) {
    _drawConnector(
      canvas,
      _Layout.rightMid(_Layout.start),
      _Layout.leftMid(_Layout.detect),
      phase: 0.0,
    );
    _drawConnector(
      canvas,
      _Layout.detectPort(0),
      _Layout.leftMid(_Layout.technical),
      phase: 0.15,
      label: '0',
    );
    _drawConnector(
      canvas,
      _Layout.detectPort(1),
      _Layout.leftMid(_Layout.agent1),
      phase: 0.35,
      label: '1',
    );
    _drawConnector(
      canvas,
      _Layout.detectPort(2),
      _Layout.leftMid(_Layout.agent2),
      phase: 0.55,
      label: '2',
    );
  }

  void _drawConnector(
      Canvas canvas,
      Offset from,
      Offset to, {
        double phase = 0,
        String? label,
      }) {
    final dx = (to.dx - from.dx).abs().clamp(40, 400).toDouble();
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(
        from.dx + dx * 0.5,
        from.dy,
        to.dx - dx * 0.5,
        to.dy,
        to.dx,
        to.dy,
      );

    final glowPaint = Paint()
      ..color = lineColor.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(path, glowPaint);

    final corePaint = Paint()
      ..color = lineColor.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, corePaint);

    _drawPort(canvas, from);
    _drawPort(canvas, to);

    if (label != null) {
      _drawLabel(canvas, label, Offset(from.dx - 16, from.dy - 8));
    }

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final length = metric.length;

    for (int i = 0; i < 4; i++) {
      final t = ((progress + phase - i * 0.07) % 1.0 + 1.0) % 1.0;
      final tangent = metric.getTangentForOffset(length * t);
      if (tangent == null) continue;
      final pos = tangent.position;
      final opacity = (1.0 - i * 0.22).clamp(0.0, 1.0);
      final dotColor = Color.lerp(lineColor, lineColor2, i / 4)!;

      final outerGlow = Paint()
        ..color = dotColor.withOpacity(opacity * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(pos, 7 - i * 0.8, outerGlow);

      final core = Paint()..color = dotColor.withOpacity(opacity);
      canvas.drawCircle(pos, 3.2 - i * 0.4, core);
    }
  }

  void _drawPort(Canvas canvas, Offset point) {
    final rect = Rect.fromCenter(center: point, width: 5, height: 14);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));

    final glow = Paint()
      ..color = lineColor.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(rrect, glow);

    final paint = Paint()..color = lineColor;
    canvas.drawRRect(rrect, paint);
  }

  void _drawLabel(Canvas canvas, String text, Offset position) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: lineColor, fontSize: 11, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) => true;
}