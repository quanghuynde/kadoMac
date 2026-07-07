import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
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

    return CoachResult(
      subjectBounds: compositionResult.subjectBounds,
      subjectCenter: compositionResult.subjectCenter,
      horizonAngle: sensorAngle,
      instruction: compositionResult.instruction,
      imageSize: compositionResult.imageSize,
      objectName: compositionResult.objectName,
      isTargetLocked: compositionResult.isTargetLocked,
      directionHint: compositionResult.directionHint,
    );
  }

  Future<CoachResult> _detectSubject(File imageFile) async {
    try {
      return await _aiService.processImage(
        InputImage.fromFilePath(imageFile.path),
      );
    } catch (e) {
      debugPrint('VisionService ML Kit detection failed: $e');
      return CoachResult(instruction: 'Cannot analyze image');
    }
  }

  void dispose() {
  }
}
