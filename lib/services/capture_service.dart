import 'dart:io';
import 'package:flutter/material.dart';
import 'package:project/models/coach_result.dart';
import 'package:project/providers/ai_coach_provider.dart';
import 'package:project/services/image_crop_service.dart';
import 'package:project/services/vision_service.dart';

class CaptureService {
  static Future<CaptureResult> processCapture(
    File file,
    AICoachState previewState,
    double sensorAngle, {
    bool cropToSubject = true,
  }) async {
    CoachResult analysisResult;

    analysisResult = await VisionService.instance.analyzeCapture(
      file,
      sensorAngle: sensorAngle,
    );

    // Dynamic crop box mapping
    final Rect? baseFrame = previewState.aiSuggestedFrame ?? previewState.result.subjectBounds;
    final Size imgSize = previewState.result.imageSize.width > 0
        ? previewState.result.imageSize
        : analysisResult.imageSize;

    File resultFile = file;
    if (cropToSubject && baseFrame != null && imgSize != Size.zero) {
      // Apply 20% margin padding to prevent cut offs
      final padW = baseFrame.width * 0.20;
      final padH = baseFrame.height * 0.20;
      final paddedFrame = Rect.fromLTRB(
        (baseFrame.left - padW).clamp(0.0, imgSize.width),
        (baseFrame.top - padH).clamp(0.0, imgSize.height),
        (baseFrame.right + padW).clamp(0.0, imgSize.width),
        (baseFrame.bottom + padH).clamp(0.0, imgSize.height),
      );

      final croppedFile = await ImageCropService.cropImageFile(
        file,
        paddedFrame,
        imgSize,
      );
      if (croppedFile != null) {
        resultFile = croppedFile;
      }
    }

    // Merge preview object info
    final mergedResult = CoachResult(
      subjectBounds: baseFrame,
      subjectCenter: previewState.result.subjectCenter,
      imageSize: analysisResult.imageSize,
      objectName: previewState.result.objectName,
      instruction: analysisResult.instruction,
      horizonAngle: sensorAngle,
    );

    return CaptureResult(
      imageFile: resultFile,
      result: mergedResult,
    );
  }

}

class CaptureResult {
  final File imageFile;
  final CoachResult result;

  CaptureResult({required this.imageFile, required this.result});
}
