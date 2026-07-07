import 'package:flutter/material.dart';

class CoachResult {
  final Rect? subjectBounds;
  final Offset? subjectCenter;
  final double horizonAngle;
  final String instruction;
  final Size imageSize;

  // Object Recognition basic info
  final String objectName;
  final bool isTargetLocked;
  final String directionHint;
  final String? thumbnailBase64;

  CoachResult({
    this.subjectBounds,
    this.subjectCenter,
    this.horizonAngle = 0.0,
    this.instruction = 'Analyzing...',
    this.imageSize = Size.zero,
    this.objectName = '',
    this.isTargetLocked = false,
    this.directionHint = '',
    this.thumbnailBase64,
  });

  CoachResult copyWith({
    Rect? subjectBounds,
    Offset? subjectCenter,
    double? horizonAngle,
    String? instruction,
    Size? imageSize,
    String? objectName,
    bool? isTargetLocked,
    String? directionHint,
    String? thumbnailBase64,
  }) {
    return CoachResult(
      subjectBounds: subjectBounds ?? this.subjectBounds,
      subjectCenter: subjectCenter ?? this.subjectCenter,
      horizonAngle: horizonAngle ?? this.horizonAngle,
      instruction: instruction ?? this.instruction,
      imageSize: imageSize ?? this.imageSize,
      objectName: objectName ?? this.objectName,
      isTargetLocked: isTargetLocked ?? this.isTargetLocked,
      directionHint: directionHint ?? this.directionHint,
      thumbnailBase64: thumbnailBase64 ?? this.thumbnailBase64,
    );
  }

  factory CoachResult.empty() => CoachResult();
}
