import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:flutter/material.dart';

/// Scene Classification Service
/// Inspired by Doka Cam's Scene Classification (EfficientNet-based)
class SceneClassifier {
  static final SceneClassifier instance = SceneClassifier._();
  ImageLabeler? _labeler;

  SceneClassifier._();

  void _ensureInitialized() {
    if (_labeler != null) return;
    final options = ImageLabelerOptions(
      confidenceThreshold: 0.5,
    );
    _labeler = ImageLabeler(options: options);
  }

  /// Classify scene from an InputImage
  /// Returns: (sceneLabel, confidence, allLabels)
  Future<SceneResult> classify(InputImage image) async {
    _ensureInitialized();
    try {
      final labels = await _labeler!.processImage(image);
      if (labels.isEmpty) {
        return SceneResult.unknown();
      }

      final top = labels.first;
      final allLabels = labels
          .take(5)
          .map((l) => LabelInfo(l.label, l.confidence))
          .toList();

      return SceneResult(
        sceneLabel: top.label,
        confidence: top.confidence,
        labels: allLabels,
      );
    } catch (e) {
      debugPrint('SceneClassifier error: $e');
      return SceneResult.unknown();
    }
  }

  /// Determine dominant color temperature from scene label
  static ColorTemperature estimateColorTemp(String scene, List<LabelInfo> labels) {
    final lower = scene.toLowerCase();
    if (lower.contains('sunset') || lower.contains('sunrise') || lower.contains('fire')) {
      return ColorTemperature.warm;
    }
    if (lower.contains('sky') || lower.contains('snow') || lower.contains('cloud')) {
      return ColorTemperature.cool;
    }
    if (lower.contains('night') || lower.contains('dark') || lower.contains('indoor')) {
      return ColorTemperature.neutral;
    }
    return ColorTemperature.neutral;
  }

  /// Estimate lighting condition
  static LightingCondition estimateLighting(String scene, double confidence) {
    final lower = scene.toLowerCase();
    if (lower.contains('night') || lower.contains('dark') || lower.contains('shadow')) {
      return LightingCondition.low;
    }
    if (lower.contains('sunset') || lower.contains('sunrise')) {
      return LightingCondition.golden;
    }
    if (lower.contains('indoor') || lower.contains('room')) {
      return LightingCondition.indoor;
    }
    if (confidence > 0.8) {
      return LightingCondition.bright;
    }
    return LightingCondition.neutral;
  }

  void dispose() {
    _labeler?.close();
    _labeler = null;
  }
}

class SceneResult {
  final String sceneLabel;
  final double confidence;
  final List<LabelInfo> labels;

  const SceneResult({
    required this.sceneLabel,
    required this.confidence,
    required this.labels,
  });

  factory SceneResult.unknown() => const SceneResult(
    sceneLabel: 'Unknown',
    confidence: 0,
    labels: [],
  );
}

class LabelInfo {
  final String label;
  final double confidence;
  const LabelInfo(this.label, this.confidence);
}

enum ColorTemperature { warm, neutral, cool }
enum LightingCondition { bright, golden, indoor, neutral, low }