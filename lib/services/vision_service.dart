import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image/image.dart' as img;
import 'package:project/models/coach_result.dart';
import 'package:project/services/ai_service.dart';

class VisionService {
  static final VisionService instance = VisionService._();

  final AIService _aiService = AIService();

  VisionService._();

  Future<CoachResult> analyzeCapture(
    File imageFile, {
    double sensorAngle = 0.0,
  }) async {
    final compositionResult = await _detectSubject(imageFile);
    final blurScore = await _computeBlurScore(imageFile.path);
    final horizonScore = _computeHorizonScore(sensorAngle);

    final mergedMetrics = Map<String, double>.from(compositionResult.metrics);
    mergedMetrics['Độ nét'] = blurScore;
    mergedMetrics['Horizon'] = horizonScore;

    final overallScore = _combineScores(
      compositionScore: compositionResult.score,
      blurScore: blurScore,
      horizonScore: horizonScore,
    );

    return CoachResult(
      subjectBounds: compositionResult.subjectBounds,
      subjectCenter: compositionResult.subjectCenter,
      horizonAngle: sensorAngle,
      instruction: compositionResult.instruction,
      score: overallScore,
      isBalanced: compositionResult.isBalanced,
      metrics: mergedMetrics,
      imageSize: compositionResult.imageSize,
    );
  }

  Future<CoachResult> _detectSubject(File imageFile) async {
    try {
      return await _aiService.processImage(
        InputImage.fromFilePath(imageFile.path),
      );
    } catch (e) {
      debugPrint('VisionService ML Kit detection failed: $e');
      return CoachResult(instruction: 'Không thể phân tích ảnh');
    }
  }

  Future<double> _computeBlurScore(String imagePath) async {
    try {
      final img.Image? decoded = img.decodeImage(
        await File(imagePath).readAsBytes(),
      );
      if (decoded == null || decoded.width < 3 || decoded.height < 3) {
        return 30.0;
      }

      final img.Image source = img.bakeOrientation(decoded);
      final img.Image sample = source.width > 640 || source.height > 640
          ? img.copyResize(
              source,
              width: source.width >= source.height ? 640 : null,
              height: source.height > source.width ? 640 : null,
            )
          : source;

      double sum = 0;
      double squaredSum = 0;
      int count = 0;

      for (int y = 1; y < sample.height - 1; y++) {
        for (int x = 1; x < sample.width - 1; x++) {
          final double center = _luminance(sample.getPixel(x, y));
          final double laplacian =
              (_luminance(sample.getPixel(x - 1, y)) +
                  _luminance(sample.getPixel(x + 1, y)) +
                  _luminance(sample.getPixel(x, y - 1)) +
                  _luminance(sample.getPixel(x, y + 1))) -
              (4 * center);

          sum += laplacian;
          squaredSum += laplacian * laplacian;
          count++;
        }
      }

      if (count == 0) return 30.0;

      final double mean = sum / count;
      final double variance = (squaredSum / count) - pow(mean, 2);
      final double focusMeasure = sqrt(max(0.0, variance));

      return ((focusMeasure / 18.0) * 100).clamp(0.0, 100.0);
    } catch (e) {
      debugPrint('VisionService blur analysis failed: $e');
      return 40.0;
    }
  }

  double _luminance(img.Pixel pixel) {
    return (0.299 * pixel.r) + (0.587 * pixel.g) + (0.114 * pixel.b);
  }

  double _computeHorizonScore(double sensorAngle) {
    final double angle = sensorAngle.abs();
    if (angle <= 3.0) return 100.0;
    if (angle <= 12.0) {
      return (100.0 - ((angle - 3.0) / 9.0) * 45.0).clamp(30.0, 100.0);
    }
    return 20.0;
  }

  double _combineScores({
    required double compositionScore,
    required double blurScore,
    required double horizonScore,
  }) {
    final double weightedComposition = compositionScore * 0.55;
    final double weightedBlur = blurScore * 0.25;
    final double weightedHorizon = horizonScore * 0.20;
    return (weightedComposition + weightedBlur + weightedHorizon).clamp(
      0.0,
      100.0,
    );
  }
}
