import 'package:flutter/material.dart';

class CoachResult {
  final Rect? subjectBounds;
  final Offset? subjectCenter;
  final double horizonAngle;
  final String instruction;
  final double score;
  final bool isBalanced;
  final Map<String, double> metrics;
  final Size imageSize;

  CoachResult({
    this.subjectBounds,
    this.subjectCenter,
    this.horizonAngle = 0.0,
    this.instruction = 'Analyzing...',
    this.score = 0.0,
    this.isBalanced = false,
    this.metrics = const {},
    this.imageSize = Size.zero,
  });

  CoachResult copyWith({
    Rect? subjectBounds,
    Offset? subjectCenter,
    double? horizonAngle,
    String? instruction,
    double? score,
    bool? isBalanced,
    Map<String, double>? metrics,
    Size? imageSize,
  }) {
    return CoachResult(
      subjectBounds: subjectBounds ?? this.subjectBounds,
      subjectCenter: subjectCenter ?? this.subjectCenter,
      horizonAngle: horizonAngle ?? this.horizonAngle,
      instruction: instruction ?? this.instruction,
      score: score ?? this.score,
      isBalanced: isBalanced ?? this.isBalanced,
      metrics: metrics ?? this.metrics,
      imageSize: imageSize ?? this.imageSize,
    );
  }

  factory CoachResult.empty() => CoachResult();
}
