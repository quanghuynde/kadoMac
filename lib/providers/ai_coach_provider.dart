import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:project/models/coach_result.dart';
import 'package:project/providers/camera_provider.dart';
import 'package:project/services/ai_service.dart';
import 'package:project/services/scene_classifier.dart';
import 'package:project/utils/one_euro_filter.dart';

/// State machine for subject tracking
enum AICoachStatus {
  idle,         
  scanning,     
  frameFound,   
  almostThere,  
}

class AICoachState {
  final CoachResult result;
  final CoachResult displayResult;
  final bool isEnabled;
  final AICoachStatus status;

  final Rect? aiSuggestedFrame;
  final Offset? aiSuggestedCenter; 

  AICoachState({
    required this.result,
    CoachResult? displayResult,
    this.isEnabled = false,
    this.status = AICoachStatus.idle,
    this.aiSuggestedFrame,
    this.aiSuggestedCenter,
  }) : displayResult = displayResult ?? result;

  AICoachState copyWith({
    CoachResult? result,
    CoachResult? displayResult,
    bool? isEnabled,
    AICoachStatus? status,
    Rect? aiSuggestedFrame,
    Offset? aiSuggestedCenter,
  }) {
    return AICoachState(
      result: result ?? this.result,
      displayResult: displayResult ?? this.displayResult,
      isEnabled: isEnabled ?? this.isEnabled,
      status: status ?? this.status,
      aiSuggestedFrame: aiSuggestedFrame ?? this.aiSuggestedFrame,
      aiSuggestedCenter: aiSuggestedCenter ?? this.aiSuggestedCenter,
    );
  }
}

class AICoachNotifier extends StateNotifier<AICoachState> {
  final AIService _aiService = AIService();
  final Ref _ref;
  bool _isBusy = false;
  bool _isStreaming = false;
  DateTime _lastProcessTime = DateTime.now();
  CameraController? _lastController;
  int _stableDetectCount = 0;
  Offset? _stickySuggestedCenter;
  int _lostDetectionCount = 0;
  String? _lastPrimarySceneCategory;

  // One Euro Filters for smooth display
  late OffsetFilter _offsetFilter;
  late RectFilter _rectFilter;
  DateTime _lastSmoothTime = DateTime.now();

  AICoachNotifier(this._ref)
    : super(AICoachState(result: CoachResult.empty(), isEnabled: false, status: AICoachStatus.idle)) {
    _offsetFilter = OffsetFilter();
    _rectFilter = RectFilter();
    _lastSmoothTime = DateTime.now();
    _ref.listen<CameraState>(
      cameraProvider,
      (previous, next) => _setupFrameListener(next),
      fireImmediately: true,
    );
  }

  void enable() => _setEnabled(true);
  void disable() => _setEnabled(false);
  void toggleEnabled() {
    if (state.isEnabled) {
      disable();
    } else {
      enable();
    }
  }

  void _setEnabled(bool enabled) {
    if (enabled) {
      state = state.copyWith(
        isEnabled: true,
        status: AICoachStatus.scanning,
        result: CoachResult.empty(),
        displayResult: CoachResult.empty(),
        aiSuggestedFrame: null,
        aiSuggestedCenter: null,
      );
      _stableDetectCount = 0;
      _stickySuggestedCenter = null;
      _lostDetectionCount = 0;
      _lastPrimarySceneCategory = null;
      _offsetFilter.reset();
      _rectFilter.reset();
      _lastSmoothTime = DateTime.now();

      if (_lastController != null) {
        _startStream(_lastController!);
      }
      HapticFeedback.mediumImpact();
    } else {
      if (_isStreaming) {
        _lastController?.stopImageStream();
        _isStreaming = false;
      }
      state = state.copyWith(
        isEnabled: false,
        status: AICoachStatus.idle,
        result: CoachResult.empty(),
        displayResult: CoachResult.empty(),
        aiSuggestedFrame: null,
        aiSuggestedCenter: null,
      );
      _ref.read(cameraProvider.notifier).setZoom(1.0);
    }
  }

  void cancelFrame() {
    state = state.copyWith(
      status: AICoachStatus.scanning,
      aiSuggestedFrame: null,
      aiSuggestedCenter: null,
      result: CoachResult.empty(),
      displayResult: CoachResult.empty(),
    );
    _stableDetectCount = 0;
    _stickySuggestedCenter = null;
    _lostDetectionCount = 0;
    _lastPrimarySceneCategory = null;
    _offsetFilter.reset();
    _rectFilter.reset();
    _lastSmoothTime = DateTime.now();
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
      if (state.isEnabled) _startStream(_lastController!);
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
      if (DateTime.now().difference(_lastProcessTime).inMilliseconds < 60) return; // Faster: ~16 FPS processing
      _processFrame(image, controller.description);
    });
  }

  Future<void> _processFrame(CameraImage image, CameraDescription camera) async {
    _isBusy = true;
    _lastProcessTime = DateTime.now();

    try {
      final inputImage = _convertCameraImage(image, camera);
      if (inputImage == null) return;

      final result = await _aiService.processImage(inputImage);
      final sceneResult = await SceneClassifier.instance.classify(inputImage);

      if (!state.isEnabled) return;

      // Identify Primary Category
      String currentCategory = 'general';
      final labels = sceneResult.labels.map((l) => l.label.toLowerCase()).toList();
      
      if (labels.any((l) => l.contains('person') || l.contains('face') || l.contains('portrait'))) {
        currentCategory = 'portrait';
      } else if (labels.any((l) => l.contains('building') || l.contains('architecture') || l.contains('city'))) {
        currentCategory = 'architecture';
      } else if (labels.any((l) => l.contains('landscape') || l.contains('nature') || l.contains('mountain'))) {
        currentCategory = 'landscape';
      } else if (labels.any((l) => l.contains('food') || l.contains('drink') || l.contains('dish'))) {
        currentCategory = 'food';
      }

      // 1. ABSOLUTE STABILITY: Only recalculate if scene category changes or lock is null
      bool sceneChanged = _lastPrimarySceneCategory != null && _lastPrimarySceneCategory != currentCategory;
      if (sceneChanged) {
        _stickySuggestedCenter = null; // Force recalculation on scene change
      }
      _lastPrimarySceneCategory = currentCategory;

      if (result.subjectCenter != null && result.subjectBounds != null) {
        _stableDetectCount++;
        _lostDetectionCount = 0;
        
        final displayResult = _smoothResult(state.displayResult, result);
        final imgWidth = result.imageSize.width;
        final imgHeight = result.imageSize.height;

        // 2. Artistic Composition Points
        if (_stickySuggestedCenter == null) {
          // Define possible targets for this category
          List<Offset> targets;
          switch (currentCategory) {
            case 'portrait':
              targets = [
                Offset(imgWidth * 0.5, imgHeight * 0.3),   // Eye level center
                Offset(imgWidth * 0.33, imgHeight * 0.33), // Upper Left
                Offset(imgWidth * 0.66, imgHeight * 0.33), // Upper Right
              ];
              break;
            case 'landscape':
              targets = [
                Offset(imgWidth * 0.382, imgHeight * 0.382), // Golden Ratio Intersections
                Offset(imgWidth * 0.618, imgHeight * 0.382),
                Offset(imgWidth * 0.382, imgHeight * 0.618),
                Offset(imgWidth * 0.618, imgHeight * 0.618),
              ];
              break;
            case 'architecture':
              targets = [
                Offset(imgWidth * 0.5, imgHeight * 0.5),   // Dead center for symmetry
                Offset(imgWidth * 0.5, imgHeight * 0.33),  // Vertical third center
              ];
              break;
            default:
              targets = [
                Offset(imgWidth / 3, imgHeight / 3),
                Offset(2 * imgWidth / 3, imgHeight / 3),
                Offset(imgWidth / 3, 2 * imgHeight / 3),
                Offset(2 * imgWidth / 3, 2 * imgHeight / 3),
                Offset(imgWidth / 2, imgHeight / 2),
              ];
          }

          // Pick the closest artistic target and LOCK IT FOREVER (until scene change)
          final currentSubjectCenter = result.subjectCenter!;
          Offset bestTarget = targets.first;
          double minDist = (currentSubjectCenter - bestTarget).distance;
          
          for (final t in targets) {
            final d = (currentSubjectCenter - t).distance;
            if (d < minDist) {
              minDist = d;
              bestTarget = t;
            }
          }
          _stickySuggestedCenter = bestTarget;
          HapticFeedback.lightImpact(); // Notify user of new stable lock
        }

        final suggestedCenter = _stickySuggestedCenter!;

        // Logic for Alignment Status
        final bool isClose = (result.subjectCenter! - suggestedCenter).distance < 80.0;
        final bool isLocked = (result.subjectCenter! - suggestedCenter).distance < 30.0;

        AICoachStatus newStatus;
        if (state.status == AICoachStatus.almostThere && !isClose) {
          // Hysteresis for status transitions
          newStatus = (result.subjectCenter! - suggestedCenter).distance < 120.0 
              ? AICoachStatus.almostThere 
              : AICoachStatus.frameFound;
        } else {
          newStatus = isClose ? AICoachStatus.almostThere : AICoachStatus.frameFound;
        }

        if (isLocked && _stableDetectCount % 10 == 0) {
           HapticFeedback.selectionClick();
        }

        state = state.copyWith(
          status: newStatus,
          aiSuggestedFrame: result.subjectBounds != null 
              ? Rect.fromCenter(
                  center: suggestedCenter, 
                  width: result.subjectBounds!.width * 1.4, 
                  height: result.subjectBounds!.height * 1.4
                )
              : null,
          aiSuggestedCenter: suggestedCenter,
          result: result,
          displayResult: displayResult,
        );
      } else {
        _stableDetectCount = 0;
        _lostDetectionCount++;
        
        // 3. Persistent Lock: Only clear if lost for a significant time (2 seconds)
        if (_lostDetectionCount > 32) {
          _stickySuggestedCenter = null;
          _lastPrimarySceneCategory = null;
        }

        state = state.copyWith(
          status: AICoachStatus.scanning,
          result: result,
          displayResult: result,
        );
      }
    } catch (e) {
      debugPrint('Process error: $e');
    } finally {
      _isBusy = false;
    }
  }

  Future<void> takePicture() async {
    final file = await _ref.read(cameraProvider.notifier).takePicture();
    if (file == null) return;
  }

  CoachResult _smoothResult(CoachResult prev, CoachResult next) {
    if (next.subjectCenter == null) return next;

    final now = DateTime.now();
    final dt = now.difference(_lastSmoothTime).inMilliseconds / 1000.0;
    _lastSmoothTime = now;

    final Offset center;
    final Rect bounds;

    if (prev.subjectCenter == null) {
      center = next.subjectCenter!;
      bounds = next.subjectBounds ?? next.subjectBounds!;
      _offsetFilter.reset();
      _rectFilter.reset();
    } else {
      center = _offsetFilter.smooth(next.subjectCenter!, dt);
      if (next.subjectBounds != null) {
        bounds = _rectFilter.smooth(next.subjectBounds!, dt);
      } else {
        bounds = next.subjectBounds!;
      }
    }

    return CoachResult(
      subjectBounds: bounds,
      subjectCenter: center,
      horizonAngle: next.horizonAngle,
      instruction: next.instruction,
      imageSize: next.imageSize,
      objectName: next.objectName,
      isTargetLocked: next.isTargetLocked,
      directionHint: next.directionHint,
    );
  }

  InputImage? _convertCameraImage(CameraImage image, CameraDescription camera) {
    try {
      final buffer = WriteBuffer();
      for (final plane in image.planes) {
        buffer.putUint8List(plane.bytes);
      }
      final bytes = buffer.done().buffer.asUint8List();
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
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
      return null;
    }
  }

  InputImageRotation _getImageRotation(CameraDescription camera) {
    switch (camera.sensorOrientation) {
      case 90: return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default: return InputImageRotation.rotation0deg;
    }
  }

  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }
}

final aiCoachProvider = StateNotifierProvider<AICoachNotifier, AICoachState>((ref) {
  return AICoachNotifier(ref);
});
