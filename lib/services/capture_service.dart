import 'dart:io';
import 'package:flutter/material.dart';
import 'package:project/models/coach_result.dart';
import 'package:project/providers/ai_coach_provider.dart';
import 'package:project/providers/settings_provider.dart';
import 'package:project/services/openai_vision_service.dart';
import 'package:project/services/image_crop_service.dart';
import 'package:project/services/vision_service.dart';

class CaptureService {
  static Future<CaptureResult> processCapture(
    File file,
    AICoachState previewState,
    double sensorAngle, {
    SettingsState? settings,
  }) async {
    CoachResult analysisResult;

    if (settings != null &&
        settings.useOpenAIVision &&
        settings.openAIApiKey.isNotEmpty) {
      analysisResult = await OpenAIVisionService.instance.evaluateLayout(
        file,
        settings.openAIApiKey,
      );
    } else {
      analysisResult = await VisionService.instance.analyzeCapture(
        file,
        sensorAngle: sensorAngle,
      );
    }

    final roiBounds =
        previewState.roiBounds ??
        analysisResult.subjectBounds ??
        previewState.result.subjectBounds ??
        Rect.fromLTWH(
          0,
          0,
          analysisResult.imageSize.width > 0
              ? analysisResult.imageSize.width
              : previewState.result.imageSize.width > 0
                  ? previewState.result.imageSize.width
                  : 1080.0,
          analysisResult.imageSize.height > 0
              ? analysisResult.imageSize.height
              : previewState.result.imageSize.height > 0
                  ? previewState.result.imageSize.height
                  : 1920.0,
        );

    final cropSourceSize = previewState.roiBounds != null
        ? previewState.result.imageSize
        : (analysisResult.imageSize.width > 0 &&
                  analysisResult.imageSize.height > 0
              ? analysisResult.imageSize
              : previewState.result.imageSize);

    final croppedFile = await ImageCropService.cropImageFile(
      file,
      roiBounds,
      cropSourceSize,
    );

    return CaptureResult(
      imageFile: croppedFile ?? file,
      result: previewState.roiBounds != null
          ? previewState.result.copyWith(
              score: analysisResult.score,
              instruction: analysisResult.instruction,
              metrics: analysisResult.metrics,
            )
          : analysisResult,
    );
  }
}

class CaptureResult {
  final File imageFile;
  final CoachResult result;

  CaptureResult({required this.imageFile, required this.result});
}
