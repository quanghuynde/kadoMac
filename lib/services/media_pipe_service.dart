import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class MediaPipeObject {
  final Rect boundingBox;
  final String label;
  final double score;

  MediaPipeObject({
    required this.boundingBox,
    required this.label,
    required this.score,
  });
}

class MediaPipeService {
  static final MediaPipeService instance = MediaPipeService._();

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool initialized = false;
  int _inputWidth = 300;
  int _inputHeight = 300;

  MediaPipeService._();

  Future<void> initialize() async {
    if (initialized) return;

    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/mediapipe_ssd.tflite',
      );
      final inputShape = _interpreter!.getInputTensor(0).shape;
      if (inputShape.length == 4) {
        _inputHeight = inputShape[1];
        _inputWidth = inputShape[2];
      }
      _labels = await _loadLabels();
      initialized = true;
      debugPrint(
        'MediaPipeService initialized: input=$_inputWidth x $_inputHeight',
      );
    } catch (e) {
      debugPrint('MediaPipeService initialization failed: $e');
      initialized = false;
    }
  }

  Future<List<String>> _loadLabels() async {
    try {
      final raw = await rootBundle.loadString('assets/models/labelmap.txt');
      return raw
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('MediaPipeService label load failed: $e');
      return [];
    }
  }

  Future<List<MediaPipeObject>> detectObjects(
    File imageFile, {
    double scoreThreshold = 0.35,
  }) async {
    if (!initialized) {
      await initialize();
    }

    if (!initialized || _interpreter == null) {
      return [];
    }

    final imageBytes = await imageFile.readAsBytes();
    final original = img.decodeImage(imageBytes);
    if (original == null) return [];

    final resized = img.copyResize(
      original,
      width: _inputWidth,
      height: _inputHeight,
      interpolation: img.Interpolation.average,
    );

    final input = List.generate(
      1,
      (_) => List.generate(
        _inputHeight,
        (_) => List.generate(_inputWidth, (_) => List.filled(3, 0.0)),
      ),
    );

    for (int y = 0; y < _inputHeight; y++) {
      for (int x = 0; x < _inputWidth; x++) {
        final pixel = resized.getPixel(x, y);
        input[0][y][x][0] = pixel.r.toDouble() / 255.0;
        input[0][y][x][1] = pixel.g.toDouble() / 255.0;
        input[0][y][x][2] = pixel.b.toDouble() / 255.0;
      }
    }

    final outputLocations = List.generate(
      1,
      (_) => List.generate(10, (_) => List.filled(4, 0.0)),
    );
    final outputClasses = List.generate(1, (_) => List.filled(10, 0.0));
    final outputScores = List.generate(1, (_) => List.filled(10, 0.0));
    final numDetections = List.filled(1, 0.0);

    try {
      _interpreter!.runForMultipleInputs(
        [input],
        {
          0: outputLocations,
          1: outputClasses,
          2: outputScores,
          3: numDetections,
        },
      );
    } catch (e) {
      debugPrint('MediaPipeService detectObjects failed: $e');
      return [];
    }

    final results = <MediaPipeObject>[];
    final originalWidth = original.width.toDouble();
    final originalHeight = original.height.toDouble();
    final count = min(10, numDetections.first.round());

    for (int i = 0; i < count; i++) {
      final score = outputScores[0][i];
      if (score < scoreThreshold) continue;

      final clsIndex = outputClasses[0][i].round();
      final label = clsIndex >= 0 && clsIndex < _labels.length
          ? _labels[clsIndex]
          : 'Object';
      final box = outputLocations[0][i];
      final ymin = box[0] * originalHeight;
      final xmin = box[1] * originalWidth;
      final ymax = box[2] * originalHeight;
      final xmax = box[3] * originalWidth;

      final rect = Rect.fromLTRB(
        xmin.clamp(0, originalWidth),
        ymin.clamp(0, originalHeight),
        xmax.clamp(0, originalWidth),
        ymax.clamp(0, originalHeight),
      );

      if (rect.width > 10 && rect.height > 10) {
        results.add(
          MediaPipeObject(boundingBox: rect, label: label, score: score),
        );
      }
    }

    return results;
  }
}
