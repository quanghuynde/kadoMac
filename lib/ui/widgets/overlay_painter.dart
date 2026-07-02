import 'dart:math';
import 'package:flutter/material.dart';
import 'package:project/models/coach_result.dart';
import 'package:project/providers/ai_coach_provider.dart';

class OverlayPainter extends CustomPainter {
  final CoachResult result;
  final double horizonAngle;
  final bool showGrid;
  final AICoachStatus status;

  OverlayPainter({
    required this.result,
    required this.horizonAngle,
    required this.showGrid,
    required this.status,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (status == AICoachStatus.analyzing) {
      _drawDotsPattern(canvas, size);
    }
    
    if (showGrid && status != AICoachStatus.analyzing) {
      _drawMinimalGrid(canvas, size);
    }
    
    _drawHorizon(canvas, size);
    
    if (result.subjectBounds != null) {
      if (status == AICoachStatus.guiding) {
        _drawGuideRing(canvas, size);
      } else if (status == AICoachStatus.adjusted || status == AICoachStatus.finished) {
        _drawGuideRectangle(canvas, size);
      }
    }
  }

  void _drawDotsPattern(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.3);
    const double spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  void _drawMinimalGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    final double w = size.width;
    final double h = size.height;
    final double dashSize = 20.0;

    final powerPoints = [
      Offset(w / 3, h / 3),
      Offset(2 * w / 3, h / 3),
      Offset(w / 3, 2 * h / 3),
      Offset(2 * w / 3, 2 * h / 3),
    ];

    for (var p in powerPoints) {
      canvas.drawLine(p - Offset(dashSize, 0), p + Offset(dashSize, 0), paint);
      canvas.drawLine(p - Offset(0, dashSize), p + Offset(0, dashSize), paint);
    }
  }

  void _drawHorizon(Canvas canvas, Size size) {
    final isLevel = horizonAngle.abs() < 1.5;
    final paint = Paint()
      ..color = isLevel ? const Color(0xFF00FFCC) : Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.2;

    final center = Offset(size.width / 2, size.height / 2);
    const double gap = 40.0;
    const double lineLen = 30.0;
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(horizonAngle * pi / 180);
    
    canvas.drawLine(Offset(-gap - lineLen, 0), Offset(-gap, 0), paint);
    canvas.drawLine(Offset(gap, 0), Offset(gap + lineLen, 0), paint);
    
    if (isLevel) {
      canvas.drawCircle(Offset.zero, 1.5, paint);
    }
    
    canvas.restore();
  }

  void _drawGuideRing(Canvas canvas, Size size) {
    if (result.imageSize == Size.zero || result.subjectCenter == null) return;

    final scaleX = size.width / result.imageSize.width;
    final scaleY = size.height / result.imageSize.height;
    
    final currentCenter = Offset(
      result.subjectCenter!.dx * scaleX,
      result.subjectCenter!.dy * scaleY,
    );

    final idealPoint = _getNearestPowerPoint(currentCenter, size);
    final distance = (currentCenter - idealPoint).distance;
    
    // Bố cục mới: Trắng khi đang tìm, Xanh khi khớp
    final bool isLocked = distance < 35;
    final Color activeColor = isLocked ? const Color(0xFF00FFCC) : Colors.white;
    
    // 1. Vẽ Vòng tròn mục tiêu (Màu trắng)
    final ringPaint = Paint()
      ..color = activeColor.withValues(alpha: isLocked ? 1.0 : 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(idealPoint, 30, ringPaint);
    canvas.drawCircle(idealPoint, 3, Paint()..color = activeColor);

    // 2. Vẽ Mũi tên động tiến dần đến tâm
    if (!isLocked) {
      _drawEnhancedDynamicArrow(canvas, currentCenter, idealPoint, Colors.white);
    } else {
      // Hiệu ứng "TỰ ĐỘNG ZOOM" khi đã khóa
      final glowPaint = Paint()
        ..color = const Color(0xFF00FFCC).withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawCircle(idealPoint, 50, glowPaint);
    }
  }

  void _drawEnhancedDynamicArrow(Canvas canvas, Offset subjectPos, Offset targetPos, Color color) {
    final dir = (targetPos - subjectPos);
    final distance = dir.distance;
    if (distance < 5.0) return;
    final normalized = dir / distance;

    // Đường dẫn "đường ray" cho người dùng biết hướng đi
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 15.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(subjectPos, targetPos, trackPaint);

    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Vẽ mũi tên ở vị trí cách tâm mục tiêu một khoảng tỉ lệ với độ chính xác
    final double arrowProgress = min(distance * 0.7, 100.0);
    final arrowBasePos = subjectPos + normalized * arrowProgress;

    final path = Path();
    // Mũi tên to hơn khi ở gần mục tiêu
    final double headSize = 15.0 + (1 - min(distance / 200, 1.0)) * 10;
    
    final p1 = arrowBasePos + _rotate(normalized, pi * 0.85) * headSize;
    final p2 = arrowBasePos + _rotate(normalized, -pi * 0.85) * headSize;

    path.moveTo(arrowBasePos.dx, arrowBasePos.dy);
    path.lineTo(p1.dx, p1.dy);
    path.lineTo(p2.dx, p2.dy);
    path.close();

    canvas.drawPath(path, Paint()..color = color);
    
    // Thêm các vạch "gia tốc" phía sau mũi tên
    for (int i = 1; i <= 3; i++) {
      final tailPos = arrowBasePos - normalized * (i * 12.0);
      final opacity = 0.8 - (i * 0.2);
      canvas.drawCircle(tailPos, 1.5, Paint()..color = color.withValues(alpha: opacity));
    }
  }

  void _drawGuideRectangle(Canvas canvas, Size size) {
    if (result.imageSize == Size.zero || result.subjectBounds == null) return;

    final scaleX = size.width / result.imageSize.width;
    final scaleY = size.height / result.imageSize.height;

    final rect = Rect.fromLTRB(
      result.subjectBounds!.left * scaleX,
      result.subjectBounds!.top * scaleY,
      result.subjectBounds!.right * scaleX,
      result.subjectBounds!.bottom * scaleY,
    );

    final paint = Paint()
      ..color = const Color(0xFF00FFCC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final RRect rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    canvas.drawRRect(rrect, paint);
    
    // Glowing corners
    _drawCorners(canvas, rect, const Color(0xFF00FFCC));
  }

  void _drawCorners(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    const double len = 20.0;

    // Top Left
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(len, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, len), paint);

    // Top Right
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(-len, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, len), paint);

    // Bottom Left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(len, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -len), paint);

    // Bottom Right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(-len, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(0, -len), paint);
  }

  Offset _getNearestPowerPoint(Offset center, Size size) {
    final tx1 = size.width / 3;
    final tx2 = 2 * size.width / 3;
    final ty1 = size.height / 3;
    final ty2 = 2 * size.height / 3;
    final points = [Offset(tx1, ty1), Offset(tx2, ty1), Offset(tx1, ty2), Offset(tx2, ty2)];
    return points.reduce((a, b) => (center - a).distance < (center - b).distance ? a : b);
  }

  Offset _rotate(Offset o, double angle) {
    return Offset(
      o.dx * cos(angle) - o.dy * sin(angle),
      o.dx * sin(angle) + o.dy * cos(angle),
    );
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) {
    return oldDelegate.result != result || oldDelegate.status != status || oldDelegate.horizonAngle != horizonAngle;
  }
}
