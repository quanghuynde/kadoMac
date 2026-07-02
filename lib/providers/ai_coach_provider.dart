import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:project/models/coach_result.dart';
import 'package:project/providers/camera_provider.dart';
import 'package:project/services/ai_service.dart';
import 'package:project/services/imagga_service.dart';

enum AICoachStatus { analyzing, guiding, adjusted, finished }

class AICoachState {
  final CoachResult result;
  final bool isEnabled;
  final bool isProcessing;
  final AICoachStatus status;
  final List<String> tags;
  final String? recommendedFilter;

  AICoachState({
    required this.result,
    this.isEnabled = true,
    this.isProcessing = false,
    this.status = AICoachStatus.analyzing,
    this.tags = const [],
    this.recommendedFilter,
  });

  AICoachState copyWith({
    CoachResult? result,
    bool? isEnabled,
    bool? isProcessing,
    AICoachStatus? status,
    List<String>? tags,
    String? recommendedFilter,
  }) {
    return AICoachState(
      result: result ?? this.result,
      isEnabled: isEnabled ?? this.isEnabled,
      isProcessing: isProcessing ?? this.isProcessing,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      recommendedFilter: recommendedFilter ?? this.recommendedFilter,
    );
  }
}

class AICoachNotifier extends StateNotifier<AICoachState> {
  final AIService _aiService = AIService();
  final ImaggaService _imaggaService = ImaggaService();
  final Ref _ref;
  bool _isBusy = false;
  bool _isImaggaAnalyzing = false;
  bool _isStreaming = false;
  DateTime _lastProcessTime = DateTime.now();
  CameraController? _lastController;
  double _currentZoom = 1.0;
  int _frameCounter = 0;

  AICoachNotifier(this._ref)
    : super(AICoachState(result: CoachResult.empty())) {
    _ref.listen<CameraState>(
      cameraProvider,
      (previous, next) => _setupFrameListener(next),
      fireImmediately: true,
    );
  }

  void toggleEnabled() {
    _setEnabled(!state.isEnabled);
  }

  void enable() {
    _setEnabled(true);
  }

  void _setEnabled(bool enabled) {
    state = state.copyWith(
      isEnabled: enabled,
      status: enabled ? AICoachStatus.analyzing : AICoachStatus.analyzing,
      tags: enabled ? state.tags : [],
    );
    _frameCounter = 0;
    _isImaggaAnalyzing = false;

    if (enabled && _lastController != null) {
      _startStream(_lastController!);
    } else {
      if (_isStreaming) {
        _lastController?.stopImageStream();
        _isStreaming = false;
      }
      _currentZoom = 1.0;
      _ref.read(cameraProvider.notifier).setZoom(1.0);
    }
  }

  void _setupFrameListener(CameraState cameraState) {
    if (cameraState.controller == null || !cameraState.isInitialized) {
      if (_isStreaming) {
        _lastController?.stopImageStream();
        _isStreaming = false;
      }
      _lastController = null;
      return;
    }

    if (_lastController != cameraState.controller) {
      if (_isStreaming) {
        _lastController?.stopImageStream();
        _isStreaming = false;
      }
      _lastController = cameraState.controller;
      if (state.isEnabled) {
        _startStream(_lastController!);
      }
      return;
    }

    if (state.isEnabled && !_isStreaming && _lastController != null) {
      _startStream(_lastController!);
    }
  }

  void _startStream(CameraController controller) {
    if (_isStreaming) return;
    _isStreaming = true;

    controller.startImageStream((image) {
      if (!state.isEnabled || _isBusy) return;

      final now = DateTime.now();
      // Tối ưu: Chỉ phân tích mỗi 200ms (5 FPS) để giữ Camera preview mượt mà
      if (now.difference(_lastProcessTime).inMilliseconds < 200) {
        return;
      }

      _processFrame(image, controller.description);
    });
  }

  Future<void> _processFrame(
    CameraImage image,
    CameraDescription camera,
  ) async {
    _isBusy = true;
    _lastProcessTime = DateTime.now();
    _frameCounter++;

    try {
      final inputImage = _convertCameraImage(image, camera);
      if (inputImage != null) {
        final result = await _aiService.processImage(inputImage);

        AICoachStatus newStatus = state.status;

        if (_frameCounter == 5 && !_isImaggaAnalyzing) {
          _triggerImaggaAnalysis();
        }

        if (_frameCounter < 8) {
          newStatus = AICoachStatus.analyzing;
        } else if (result.score < 85) {
          // Ngưỡng khắt khe hơn để hiện Guide Ring
          newStatus = AICoachStatus.guiding;
        } else {
          newStatus = AICoachStatus.finished;
        }

        state = state.copyWith(result: result, status: newStatus);

        // Luôn xử lý zoom dựa trên điểm số thực tế
        if (result.subjectCenter != null) {
          _handleAutoZoom(result);
        }
      }
    } catch (e) {
      debugPrint('Error processing frame: $e');
    } finally {
      _isBusy = false;
    }
  }

  void _handleAutoZoom(CoachResult result) {
    if (result.subjectCenter == null || result.imageSize == Size.zero) return;

    // Sử dụng ngưỡng điểm số cao và ổn định hơn để tránh giật
    if (result.score >= 88) {
      if (_currentZoom < 1.4) {
        // Zoom vào từ từ
        _currentZoom += 0.02;
        _ref.read(cameraProvider.notifier).setZoom(_currentZoom);
      }
    } else if (result.score < 70) {
      if (_currentZoom > 1.0) {
        // Zoom ra từ từ để tránh giật hình
        _currentZoom -= 0.05;
        if (_currentZoom < 1.0) _currentZoom = 1.0;
        _ref.read(cameraProvider.notifier).setZoom(_currentZoom);
      }
    }
  }

  Future<void> _triggerImaggaAnalysis() async {
    if (_isImaggaAnalyzing ||
        _lastController == null ||
        _lastController!.value.isTakingPicture)
      return;
    _isImaggaAnalyzing = true;

    try {
      // Capture a single frame to a temporary file
      final XFile photo = await _lastController!.takePicture();

      // Analyze with Imagga
      final tagResult = await _imaggaService.analyzeImage(photo.path);

      if (tagResult.containsKey('result')) {
        final tagsData = tagResult['result']['tags'] as List;
        final tags = tagsData
            .take(5)
            .map((t) => t['tag']['en'].toString())
            .toList();

        state = state.copyWith(
          tags: tags,
          recommendedFilter: _mapTagsToFilter(tags),
        );
      }

      // Delete temporary file
      final file = File(photo.path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Imagga analysis error: $e');
    } finally {
      _isImaggaAnalyzing = false;
    }
  }

  String _mapTagsToFilter(List<String> tags) {
    final lowerTags = tags.map((t) => t.toLowerCase()).toList();
    if (lowerTags.any(
      (t) => t.contains('nature') || t.contains('tree') || t.contains('grass'),
    ))
      return 'Summer Fresh';
    if (lowerTags.any((t) => t.contains('food') || t.contains('drink')))
      return 'Vivid Food';
    if (lowerTags.any(
      (t) =>
          t.contains('person') ||
          t.contains('face') ||
          t.contains('man') ||
          t.contains('woman'),
    ))
      return 'Soft Portrait';
    return 'Classic F16';
  }

  InputImage? _convertCameraImage(CameraImage image, CameraDescription camera) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final InputImageFormat? format = InputImageFormatValue.fromRawValue(
        image.format.raw,
      );
      if (format == null) return null;

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: _getImageRotation(camera),
          format: format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('Conversion error: $e');
      return null;
    }
  }

  InputImageRotation _getImageRotation(CameraDescription camera) {
    switch (camera.sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }
}

final aiCoachProvider = StateNotifierProvider<AICoachNotifier, AICoachState>((
  ref,
) {
  return AICoachNotifier(ref);
});
