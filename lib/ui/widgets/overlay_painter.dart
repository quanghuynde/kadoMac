import 'dart:math';
import 'package:flutter/material.dart';
import 'package:project/models/coach_result.dart';
import 'package:project/providers/ai_coach_provider.dart';

class OverlayPainter extends CustomPainter {
  final CoachResult result;
  final double horizonAngle;
  final bool showGrid;
  final AICoachStatus status;
  final Rect? aiSuggestedFrame;
  final Offset? aiSuggestedCenter;
  final double scanningProgress; // 0-1 for animated scanning
  final double frameLockProgress; // 0-1 for framed animation
  final int sensorOrientation;
  final bool isFrontCamera;

  OverlayPainter({
    required this.result,
    required this.horizonAngle,
    required this.showGrid,
    required this.status,
    required this.sensorOrientation,
    required this.isFrontCamera,
    this.aiSuggestedFrame,
    this.aiSuggestedCenter,
    this.scanningProgress = 0,
    this.frameLockProgress = 0,
  });

  double _translateX(double x, Size canvasSize) {
    if (result.imageSize == Size.zero) return x;
    double calculatedX;
    if (sensorOrientation == 90 || sensorOrientation == 270) {
      calculatedX = x * canvasSize.width / result.imageSize.height;
    } else {
      calculatedX = x * canvasSize.width / result.imageSize.width;
    }
    if (isFrontCamera) {
      return canvasSize.width - calculatedX;
    }
    return calculatedX;
  }

  double _translateY(double y, Size canvasSize) {
    if (result.imageSize == Size.zero) return y;
    if (sensorOrientation == 90 || sensorOrientation == 270) {
      return y * canvasSize.height / result.imageSize.width;
    } else {
      return y * canvasSize.height / result.imageSize.height;
    }
  }

  Offset _translateOffset(Offset offset, Size canvasSize) {
    return Offset(
      _translateX(offset.dx, canvasSize),
      _translateY(offset.dy, canvasSize),
    );
  }

  // Colors per design spec
  static const Color _colorTarget = Colors.white;
  static const Color _colorSubject = Color(0xFF00FFCC);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Grid (Rule of Thirds)
    if (showGrid) {
      _drawGrid(canvas, size);
    }

    if (status == AICoachStatus.idle) return;

    // 2. Draw Scanning indicator
    if (status == AICoachStatus.scanning) {
      _drawScanning(canvas, size);
      return;
    }

    // 3. Draw Doka-style connecting line guidance
    if (aiSuggestedCenter != null && result.subjectCenter != null && result.imageSize != Size.zero) {
      final targetPos = _translateOffset(aiSuggestedCenter!, size);
      final subjectPos = _translateOffset(result.subjectCenter!, size);

      // Draw Guide Line (The "connection")
      _drawGuideLine(canvas, targetPos, subjectPos, _colorSubject);

      // Draw Target (Aim Ring)
      _drawTargetMarker(canvas, targetPos, _colorTarget, scanningProgress);

      // Draw Subject (Crosshair following the object)
      _drawSubjectMarker(canvas, subjectPos, _colorSubject);

      // Draw Framing Box (Expanding from small to large)
      if (frameLockProgress > 0) {
        _drawFramingBox(canvas, targetPos, frameLockProgress);
      }
    }
  }

  void _drawFramingBox(Canvas canvas, Offset center, double progress) {
    // Animation: Small to Large (Flexible based on AI detection)
    final initialSize = 80.0;
    
    final finalWidth = aiSuggestedFrame != null 
        ? _translateX(aiSuggestedFrame!.width, canvas.getLocalClipBounds().size) 
        : 240.0;
    final finalHeight = aiSuggestedFrame != null 
        ? _translateY(aiSuggestedFrame!.height, canvas.getLocalClipBounds().size) 
        : 240.0;

    final currentWidth = initialSize + (finalWidth - initialSize) * progress;
    final currentHeight = initialSize + (finalHeight - initialSize) * progress;
    
    final rect = Rect.fromCenter(center: center, width: currentWidth, height: currentHeight);
    const borderRadius = 24.0;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(borderRadius));

    // Paint for the gradient border
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final gradient = SweepGradient(
      center: Alignment.center,
      colors: const [
        Color(0xFFFF66CC), // Pink
        Color(0xFF6699FF), // Blue
        Color(0xFF99FF66), // Green
        Color(0xFFFFFF66), // Yellow
        Color(0xFFFF66CC), // Back to Pink
      ],
    );

    paint.shader = gradient.createShader(rect);

    // Subtle glow/shadow
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF6699FF).withValues(alpha: 0.3 * progress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0,
    );

    canvas.drawRRect(rrect, paint);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5) // Highly visible white lines
      ..strokeWidth = 1.0;

    // Vertical lines
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);

    // Horizontal lines
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), paint);
  }

  void _drawGuideLine(Canvas canvas, Offset target, Offset subject, Color color) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.5; // Slightly thicker
    
    final distance = (target - subject).distance;
    if (distance < 10) return;

    final direction = (target - subject) / distance;
    
    // Draw fine elastic dots with slight variation
    for (double i = 8; i < distance - 8; i += 10) {
      final alpha = (0.2 + (0.4 * (1.0 - i / distance))).clamp(0.1, 0.6);
      canvas.drawCircle(subject + direction * i, 1.2, paint..color = color.withValues(alpha: alpha));
    }
  }

  void _drawTargetMarker(Canvas canvas, Offset center, Color color, double progress) {
    final pulse = sin(progress * 2 * pi) * 0.05 + 1.0;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Large ring
    canvas.drawCircle(center, 28 * pulse, paint);
    // Inner dot
    canvas.drawCircle(center, 2.0, Paint()..color = color.withValues(alpha: 0.8));
  }

  void _drawSubjectMarker(Canvas canvas, Offset center, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Small ring
    canvas.drawCircle(center, 12, paint);

    // Crosshair lines
    const len = 6.0;
    canvas.drawLine(center - const Offset(len, 0), center + const Offset(len, 0), paint);
    canvas.drawLine(center - const Offset(0, len), center + const Offset(0, len), paint);
  }

  void _drawScanning(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final frameW = size.width * 0.72;
    final frameH = size.height * 0.48;
    final frameRect = Rect.fromCenter(center: center, width: frameW, height: frameH);
    const teal = Color(0xFF00FFCC);

    final cp = Paint()..color = teal..strokeWidth = 2.0..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    const cornerRadius = 24.0;
    
    canvas.drawArc(Rect.fromLTWH(frameRect.left, frameRect.top, cornerRadius*2, cornerRadius*2), pi, pi/2, false, cp);
    canvas.drawArc(Rect.fromLTWH(frameRect.right - cornerRadius*2, frameRect.top, cornerRadius*2, cornerRadius*2), -pi/2, pi/2, false, cp);
    canvas.drawArc(Rect.fromLTWH(frameRect.left, frameRect.bottom - cornerRadius*2, cornerRadius*2, cornerRadius*2), pi/2, pi/2, false, cp);
    canvas.drawArc(Rect.fromLTWH(frameRect.right - cornerRadius*2, frameRect.bottom - cornerRadius*2, cornerRadius*2, cornerRadius*2), 0, pi/2, false, cp);

    final sweepY = frameRect.top + frameRect.height * scanningProgress;
    canvas.drawLine(Offset(frameRect.left + 20, sweepY), Offset(frameRect.right - 20, sweepY), Paint()..color = teal.withValues(alpha: 0.8)..strokeWidth = 1.0);
  }

  @override
  bool shouldRepaint(covariant OverlayPainter old) => true;
}
