import 'dart:math';
import 'package:flutter/material.dart';

/// Custom painter for scanner overlay with transparent cutout
class ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final Color overlayColor;

  ScannerOverlayPainter({
    required this.borderColor,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = min(size.width, size.height) - 40;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;

    final Rect scanArea = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    // Draw overlay
    final Path overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanArea, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()..color = overlayColor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for corner decorations on the scan area
class CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;

  CornerPainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = min(size.width, size.height) - 40;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;
    final double right = left + scanAreaSize;
    final double bottom = top + scanAreaSize;

    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top + 8)
        ..quadraticBezierTo(left, top, left + 8, top)
        ..lineTo(left + cornerLength, top),
      paint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - cornerLength, top)
        ..lineTo(right - 8, top)
        ..quadraticBezierTo(right, top, right, top + 8)
        ..lineTo(right, top + cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, bottom - cornerLength)
        ..lineTo(left, bottom - 8)
        ..quadraticBezierTo(left, bottom, left + 8, bottom)
        ..lineTo(left + cornerLength, bottom),
      paint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - cornerLength, bottom)
        ..lineTo(right - 8, bottom)
        ..quadraticBezierTo(right, bottom, right, bottom - 8)
        ..lineTo(right, bottom - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for pulsing corner effect animation
class PulsingCornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double offset;

  PulsingCornerPainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = min(size.width, size.height) - 40 + (offset * 2);
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;
    final double right = left + scanAreaSize;
    final double bottom = top + scanAreaSize;

    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double adjustedCornerLength = cornerLength + offset;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, top + adjustedCornerLength)
        ..lineTo(left, top + 8)
        ..quadraticBezierTo(left, top, left + 8, top)
        ..lineTo(left + adjustedCornerLength, top),
      paint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - adjustedCornerLength, top)
        ..lineTo(right - 8, top)
        ..quadraticBezierTo(right, top, right, top + 8)
        ..lineTo(right, top + adjustedCornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, bottom - adjustedCornerLength)
        ..lineTo(left, bottom - 8)
        ..quadraticBezierTo(left, bottom, left + 8, bottom)
        ..lineTo(left + adjustedCornerLength, bottom),
      paint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - adjustedCornerLength, bottom)
        ..lineTo(right - 8, bottom)
        ..quadraticBezierTo(right, bottom, right, bottom - 8)
        ..lineTo(right, bottom - adjustedCornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant PulsingCornerPainter oldDelegate) {
    return oldDelegate.offset != offset || oldDelegate.color != color;
  }
}

