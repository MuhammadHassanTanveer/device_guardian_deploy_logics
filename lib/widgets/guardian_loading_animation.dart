import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Guardian Shield Animation - Security shield with scanning effect
/// Perfect for Device Guardian Admin app
class GuardianLoadingAnimation extends StatefulWidget {
  final double size;
  final Color? primaryColor;
  final Color? secondaryColor;

  const GuardianLoadingAnimation({
    super.key,
    this.size = 100,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  State<GuardianLoadingAnimation> createState() =>
      _GuardianLoadingAnimationState();
}

class _GuardianLoadingAnimationState extends State<GuardianLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = widget.primaryColor ?? colorScheme.primary;
    final secondaryColor = widget.secondaryColor ?? Colors.white;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _GuardianShieldPainter(
              progress: _controller.value,
              primaryColor: primaryColor,
              secondaryColor: secondaryColor,
            ),
          );
        },
      ),
    );
  }
}

class _GuardianShieldPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  _GuardianShieldPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Pulsing glow effect
    final pulseValue = (math.sin(progress * 2 * math.pi) + 1) / 2;
    final glowRadius = size.width * 0.42 + (pulseValue * size.width * 0.05);
    
    // Draw outer glow
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15 + pulseValue * 0.1)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.08);
    canvas.drawCircle(center, glowRadius, glowPaint);

    // Draw shield shape
    final shieldPath = _createShieldPath(center, size);
    
    // Shield fill with gradient effect
    final shieldFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor,
          primaryColor.withValues(alpha: 0.7),
        ],
      ).createShader(Rect.fromCenter(center: center, width: size.width, height: size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(shieldPath, shieldFillPaint);

    // Shield border
    final shieldBorderPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.025;
    canvas.drawPath(shieldPath, shieldBorderPaint);

    // Draw scanning line effect
    _drawScanLine(canvas, size, center, shieldPath);

    // Draw lock/guardian icon in center
    _drawGuardianIcon(canvas, size, center);

    // Draw rotating dots around shield
    _drawOrbitingDots(canvas, size, center);
  }

  Path _createShieldPath(Offset center, Size size) {
    final path = Path();
    final shieldWidth = size.width * 0.55;
    final shieldHeight = size.height * 0.65;
    
    // Shield top
    path.moveTo(center.dx, center.dy - shieldHeight * 0.45);
    
    // Top right curve
    path.quadraticBezierTo(
      center.dx + shieldWidth * 0.5,
      center.dy - shieldHeight * 0.35,
      center.dx + shieldWidth * 0.5,
      center.dy - shieldHeight * 0.1,
    );
    
    // Right side to bottom point
    path.quadraticBezierTo(
      center.dx + shieldWidth * 0.5,
      center.dy + shieldHeight * 0.2,
      center.dx,
      center.dy + shieldHeight * 0.55,
    );
    
    // Bottom point to left side
    path.quadraticBezierTo(
      center.dx - shieldWidth * 0.5,
      center.dy + shieldHeight * 0.2,
      center.dx - shieldWidth * 0.5,
      center.dy - shieldHeight * 0.1,
    );
    
    // Left side to top
    path.quadraticBezierTo(
      center.dx - shieldWidth * 0.5,
      center.dy - shieldHeight * 0.35,
      center.dx,
      center.dy - shieldHeight * 0.45,
    );
    
    path.close();
    return path;
  }

  void _drawScanLine(Canvas canvas, Size size, Offset center, Path shieldPath) {
    // Animated scan line moving up and down
    final scanProgress = (math.sin(progress * 2 * math.pi) + 1) / 2;
    final scanY = center.dy - size.height * 0.25 + (scanProgress * size.height * 0.5);
    
    canvas.save();
    canvas.clipPath(shieldPath);
    
    // Gradient scan line
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          secondaryColor.withValues(alpha: 0.0),
          secondaryColor.withValues(alpha: 0.6),
          secondaryColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(center.dx - size.width * 0.3, scanY - 2, size.width * 0.6, 4));
    
    canvas.drawRect(
      Rect.fromLTWH(center.dx - size.width * 0.3, scanY - 2, size.width * 0.6, 4),
      scanPaint,
    );
    
    canvas.restore();
  }

  void _drawGuardianIcon(Canvas canvas, Size size, Offset center) {
    final iconPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    // Draw a checkmark with animation
    final checkProgress = ((progress * 2) % 1.0).clamp(0.0, 1.0);
    
    if (progress < 0.5) {
      // First half: draw checkmark
      final checkPath = Path();
      final startX = center.dx - size.width * 0.12;
      final startY = center.dy;
      final midX = center.dx - size.width * 0.02;
      final midY = center.dy + size.height * 0.08;
      final endX = center.dx + size.width * 0.15;
      final endY = center.dy - size.height * 0.1;
      
      checkPath.moveTo(startX, startY);
      if (checkProgress < 0.5) {
        final t = checkProgress * 2;
        checkPath.lineTo(
          startX + (midX - startX) * t,
          startY + (midY - startY) * t,
        );
      } else {
        checkPath.lineTo(midX, midY);
        final t = (checkProgress - 0.5) * 2;
        checkPath.lineTo(
          midX + (endX - midX) * t,
          midY + (endY - midY) * t,
        );
      }
      canvas.drawPath(checkPath, iconPaint);
    } else {
      // Second half: full checkmark
      final checkPath = Path();
      checkPath.moveTo(center.dx - size.width * 0.12, center.dy);
      checkPath.lineTo(center.dx - size.width * 0.02, center.dy + size.height * 0.08);
      checkPath.lineTo(center.dx + size.width * 0.15, center.dy - size.height * 0.1);
      canvas.drawPath(checkPath, iconPaint);
    }
  }

  void _drawOrbitingDots(Canvas canvas, Size size, Offset center) {
    final orbitRadius = size.width * 0.48;
    
    for (int i = 0; i < 3; i++) {
      final angle = progress * 2 * math.pi + (i * 2 * math.pi / 3);
      final dotX = center.dx + orbitRadius * math.cos(angle);
      final dotY = center.dy + orbitRadius * math.sin(angle);
      
      // Fading effect based on position
      final fadeProgress = (math.sin(angle) + 1) / 2;
      final dotOpacity = 0.3 + fadeProgress * 0.7;
      final dotSize = size.width * 0.025 + fadeProgress * size.width * 0.015;
      
      final dotPaint = Paint()
        ..color = secondaryColor.withValues(alpha: dotOpacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(dotX, dotY), dotSize, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GuardianShieldPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Simple Rotating Arc for Buttons
class GuardianButtonLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const GuardianButtonLoader({
    super.key,
    this.size = 20,
    this.color,
  });

  @override
  State<GuardianButtonLoader> createState() => _GuardianButtonLoaderState();
}

class _GuardianButtonLoaderState extends State<GuardianButtonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Colors.white;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * 2 * math.pi,
            child: CustomPaint(
              painter: _ArcPainter(color: color),
            ),
          );
        },
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;

  _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, trackPaint);

    // Arc
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 1.2, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) => false;
}

/// Scaling Dots Loader
class GuardianDotsLoader extends StatefulWidget {
  final double dotSize;
  final Color? color;
  final double spacing;

  const GuardianDotsLoader({
    super.key,
    this.dotSize = 10,
    this.color,
    this.spacing = 6,
  });

  @override
  State<GuardianDotsLoader> createState() => _GuardianDotsLoaderState();
}

class _GuardianDotsLoaderState extends State<GuardianDotsLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: widget.dotSize * 3 + widget.spacing * 2,
      height: widget.dotSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final delay = i * 0.2;
              final t = (_controller.value + delay) % 1.0;
              final scale = t < 0.5 
                  ? 0.5 + t 
                  : 1.5 - t;
              final opacity = t < 0.5 
                  ? 0.3 + t * 1.4 
                  : 1.0 - (t - 0.5) * 1.4;
              
              return Padding(
                padding: EdgeInsets.only(
                  right: i < 2 ? widget.spacing : 0,
                ),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: widget.dotSize,
                    height: widget.dotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: opacity.clamp(0.3, 1.0)),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

