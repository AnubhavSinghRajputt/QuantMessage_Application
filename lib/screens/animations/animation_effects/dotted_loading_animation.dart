import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ============================================================
/// DottedLoadingAnimationAlt  (Variant B - "Pulsing Wave")
/// ============================================================
/// A circular dotted loading indicator in GREEN where the dots
/// stay fixed in a circle, and a "pulse" of size + opacity
/// travels around the ring, one dot after another - like a
/// wave chasing itself in a loop.
///
/// HOW TO USE ON ANOTHER SCREEN:
/// -----------------------------------------------------------
/// 1. Copy this file into your project (e.g. lib/widgets/).
/// 2. Import it wherever you need a loading state:
///
///      import 'dotted_loading_animation_alt.dart';
///
/// 3. Drop it into your widget tree:
///
///      Center(
///        child: DottedLoadingAnimationAlt(),
///      )
///
/// 4. Customize if needed:
///
///      DottedLoadingAnimationAlt(
///        size: 80,
///        dotCount: 10,
///        color: Colors.green,
///        duration: Duration(milliseconds: 1400),
///      )
///
/// 5. Typical integration pattern with a loading flag:
///
///      isLoading
///        ? const DottedLoadingAnimationAlt()
///        : YourActualContentWidget()
/// ============================================================

class DottedLoadingAnimationAlt extends StatefulWidget {
  final double size;
  final int dotCount;
  final Color color;
  final Duration duration;

  const DottedLoadingAnimationAlt({
    Key? key,
    this.size = 60.0,
    this.dotCount = 8,
    this.color = const Color(0xFF2ECC71), // green
    this.duration = const Duration(milliseconds: 1400),
  }) : super(key: key);

  @override
  State<DottedLoadingAnimationAlt> createState() =>
      _DottedLoadingAnimationAltState();
}

class _DottedLoadingAnimationAltState extends State<DottedLoadingAnimationAlt>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
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
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _WaveDotPainter(
            progress: _controller.value,
            dotCount: widget.dotCount,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _WaveDotPainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0 loop
  final int dotCount;
  final Color color;

  _WaveDotPainter({
    required this.progress,
    required this.dotCount,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - (size.width / 10);
    final baseDotRadius = size.width / 16;

    for (int i = 0; i < dotCount; i++) {
      final angle = 2 * math.pi * i / dotCount;
      final dx = center.dx + radius * math.cos(angle);
      final dy = center.dy + radius * math.sin(angle);

      // Phase-shift each dot so the "pulse" travels around the ring.
      final phase = (progress - (i / dotCount)) % 1.0;
      // Pulse strength peaks when phase is near 0, using a smooth curve.
      final pulse = math.pow(1 - (phase < 0.5 ? phase * 2 : (1 - phase) * 2)
          .clamp(0.0, 1.0),
          2)
          .toDouble();

      final scale = 0.6 + (0.8 * pulse);
      final opacity = (0.25 + (0.75 * pulse)).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dx, dy), baseDotRadius * scale, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveDotPainter oldDelegate) => true;
}