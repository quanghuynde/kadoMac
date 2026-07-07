import 'dart:math';
import 'dart:ui';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:project/models/coach_result.dart';

class AIService {
  late ObjectDetector _objectDetector;

  AIService() {
    _initialize();
  }

  void _initialize() {
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  Future<CoachResult> processImage(InputImage inputImage) async {
    try {
      final objects = await _objectDetector.processImage(inputImage);

      if (objects.isEmpty) {
        return CoachResult(instruction: 'Analyzing...');
      }

      final mainSubject = objects.reduce((a, b) {
        final areaA = a.boundingBox.width * a.boundingBox.height;
        final areaB = b.boundingBox.width * b.boundingBox.height;
        return areaA > areaB ? a : b;
      });

      final bounds = mainSubject.boundingBox;
      final center = Offset(
        bounds.left + bounds.width / 2,
        bounds.top + bounds.height / 2,
      );

      final metadata = inputImage.metadata;
      final imgWidth = metadata?.size.width ?? 0;
      final imgHeight = metadata?.size.height ?? 0;

      // Crosshair alignment
      final crosshairPos = Offset(imgWidth / 2, imgHeight / 2);
      final dx = center.dx - crosshairPos.dx;
      final dy = center.dy - crosshairPos.dy;
      final distance = sqrt(dx * dx + dy * dy);
      final threshold = imgWidth * 0.08;
      final isLocked = distance < threshold;

      // Direction hint
      String directionHint = '';
      if (!isLocked && distance > 5.0) {
        if (distance < imgWidth * 0.10) {
          directionHint = 'Gần đến rồi...';
        } else {
          final hints = <String>[];
          if (dy.abs() > imgWidth * 0.03) {
            hints.add(dy > 0 ? 'Di chuyển xuống' : 'Di chuyển lên');
          }
          if (dx.abs() > imgWidth * 0.03) {
            hints.add(dx > 0 ? 'Di chuyển phải' : 'Di chuyển trái');
          }
          final subjectSizeRatio =
              (bounds.width * bounds.height) / (imgWidth * imgHeight);
          if (subjectSizeRatio < 0.03) {
            hints.add('Di chuyển lại gần');
          } else if (subjectSizeRatio > 0.5) {
            hints.add('Di chuyển xa');
          }
          directionHint = hints.join(', ');
        }
      }

      String instruction;
      if (isLocked) {
        instruction = 'Đã khóa mục tiêu';
      } else if (directionHint.isNotEmpty) {
        instruction = directionHint;
      } else {
        instruction = 'Aim at the colored ring';
      }

      return CoachResult(
        subjectBounds: bounds,
        subjectCenter: center,
        instruction: instruction,
        imageSize: Size(imgWidth, imgHeight),
        objectName: '',
        isTargetLocked: isLocked,
        directionHint: directionHint,
      );
    } catch (e) {
      return CoachResult(instruction: 'Error: ${e.toString()}');
    }
  }

  void dispose() => _objectDetector.close();
}
