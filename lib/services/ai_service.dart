import 'dart:ui';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:project/models/coach_result.dart';

class AIService {
  late ObjectDetector _objectDetector;
  late SubjectSegmenter _subjectSegmenter;

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

    final segmenterOptions = SubjectSegmenterOptions(
      enableForegroundConfidenceMask: true,
      enableForegroundBitmap: false,
      enableMultipleSubjects: SubjectResultOptions(
        enableConfidenceMask: true,
        enableSubjectBitmap: false,
      ),
    );
    _subjectSegmenter = SubjectSegmenter(options: segmenterOptions);
  }

  Future<CoachResult> processImage(InputImage inputImage) async {
    try {
      final objects = await _objectDetector.processImage(inputImage);
      
      if (objects.isEmpty) {
        return CoachResult(instruction: 'Đang tìm chủ thể...');
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
      if (metadata == null) return CoachResult(subjectBounds: bounds, subjectCenter: center, instruction: 'Đang phân tích...');

      final imgWidth = metadata.size.width;
      final imgHeight = metadata.size.height;

      return _analyzeComposition(center, bounds, imgWidth, imgHeight);
    } catch (e) {
      return CoachResult(instruction: 'Lỗi: ${e.toString()}');
    }
  }

  CoachResult _analyzeComposition(Offset center, Rect bounds, double width, double height) {
    // 1. Rule of Thirds Points
    final tx1 = width / 3;
    final tx2 = 2 * width / 3;
    final ty1 = height / 3;
    final ty2 = 2 * height / 3;

    // 2. Center Point (for Symmetry)
    final cx = width / 2;
    final cy = height / 2;

    // 3. Golden Ratio Points (Phi Grid - approx 0.38 / 0.62)
    final gx1 = width * 0.382;
    final gx2 = width * 0.618;
    final gy1 = height * 0.382;
    final gy2 = height * 0.618;

    final targetPoints = [
      Offset(tx1, ty1), Offset(tx2, ty1), Offset(tx1, ty2), Offset(tx2, ty2), // 1/3
      Offset(cx, cy), // Center
      Offset(gx1, gy1), Offset(gx2, gy1), Offset(gx1, gy2), Offset(gx2, gy2), // Golden
    ];

    // Priority logic: If subject is very large, prefer Center (Symmetry)
    double subjectSizeRatio = (bounds.width * bounds.height) / (width * height);
    Offset nearestPoint;
    double minDist;

    if (subjectSizeRatio > 0.45) {
      // Large subject -> Symmetry priority
      nearestPoint = Offset(cx, cy);
      minDist = (center - nearestPoint).distance;
    } else {
      // Normal/Small subject -> Nearest point among all candidates
      nearestPoint = targetPoints[0];
      minDist = (center - targetPoints[0]).distance;

      for (var point in targetPoints) {
        double dist = (center - point).distance;
        if (dist < minDist) {
          minDist = dist;
          nearestPoint = point;
        }
      }
    }

    String instruction = 'Bố cục hoàn hảo!';
    if (minDist > width * 0.1) {
      final dx = nearestPoint.dx - center.dx;
      final dy = nearestPoint.dy - center.dy;

      if (dx.abs() > dy.abs()) {
        instruction = dx > 0 ? 'Dịch sang phải' : 'Dịch sang trái';
      } else {
        instruction = dy > 0 ? 'Dịch xuống dưới' : 'Dịch lên trên';
      }
    }

    double compositionScore = (1.0 - (minDist / (width / 2))).clamp(0.0, 1.0) * 100;
    
    double subjectSizeRatio = (bounds.width * bounds.height) / (width * height);
    if (subjectSizeRatio < 0.05) {
      instruction = 'Lại gần hơn';
      compositionScore *= 0.8;
    } else if (subjectSizeRatio > 0.6) {
      instruction = 'Lùi xa ra';
      compositionScore *= 0.8;
    }

    return CoachResult(
      subjectBounds: bounds,
      subjectCenter: center,
      instruction: instruction,
      score: compositionScore,
      imageSize: Size(width, height),
      metrics: {
        'Quy tắc 1/3': compositionScore,
        'Kích thước chủ thể': subjectSizeRatio * 100,
      },
    );
  }

  void dispose() {
    _objectDetector.close();
    _subjectSegmenter.close();
  }
}
