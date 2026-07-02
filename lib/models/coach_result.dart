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

  factory CoachResult.empty() => CoachResult();
}
