import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A circular progress ring with a carved/embossed "3D" look — built with
/// CustomPainter instead of a flat progress indicator package.
///
/// Depth comes from three layers:
/// 1. A soft drop shadow behind the ring (lifts it off the card)
/// 2. A sweep gradient on the track (dark→light→dark), like a carved groove
/// 3. A gradient + glossy highlight on the progress arc itself
class DepthProgressRing extends StatelessWidget {
  final double percent; // 0.0 to 1.0
  final double radius;
  final double strokeWidth;
  final Color color; // primary progress color
  final Color highlightColor; // secondary/accent for the gloss highlight
  final Color trackBase; // base color of the unfilled track
  final Widget? center;

  const DepthProgressRing({
    super.key,
    required this.percent,
    this.radius = 80,
    this.strokeWidth = 14,
    required this.color,
    required this.highlightColor,
    required this.trackBase,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(radius * 2, radius * 2),
            painter: _DepthRingPainter(
              percent: percent.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              color: color,
              highlightColor: highlightColor,
              trackBase: trackBase,
            ),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

class _DepthRingPainter extends CustomPainter {
  final double percent;
  final double strokeWidth;
  final Color color;
  final Color highlightColor;
  final Color trackBase;

  _DepthRingPainter({
    required this.percent,
    required this.strokeWidth,
    required this.color,
    required this.highlightColor,
    required this.trackBase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ringRadius = (size.shortestSide / 2) - strokeWidth / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: ringRadius);

    // 1. Drop shadow behind the ring — gives it lift off the card surface.
    canvas.drawCircle(
      center.translate(0, 3),
      ringRadius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // 2. Track — a sweep gradient simulating a carved groove catching light.
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          trackBase.withValues(alpha: 0.55),
          Colors.white.withValues(alpha: 0.9),
          trackBase.withValues(alpha: 0.55),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawCircle(center, ringRadius, trackPaint);

    // 3. Progress arc — diagonal gradient for a raised, glossy look.
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.85), color, highlightColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * percent,
      false,
      progressPaint,
    );

    // 4. Thin bright sheen along the outer edge of the filled arc.
    final sheenRect = Rect.fromCircle(
      center: center,
      radius: ringRadius - strokeWidth / 2 + 1.5,
    );
    canvas.drawArc(
      sheenRect,
      -math.pi / 2,
      2 * math.pi * percent,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _DepthRingPainter oldDelegate) =>
      oldDelegate.percent != percent ||
      oldDelegate.color != color ||
      oldDelegate.highlightColor != highlightColor ||
      oldDelegate.trackBase != trackBase;
}
