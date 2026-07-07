import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cameraProvider = StateNotifierProvider<CameraNotifier, CameraState>((
  ref,
) {
  return CameraNotifier();
});

class CameraState {
  final CameraController? controller;
  final bool isInitialized;
  final List<CameraDescription> cameras;
  final int selectedCameraIndex;
  final double zoomLevel;
  final String? error;
  final FlashMode flashMode;
  final Duration timerDuration;
  final String aspectRatio;

  final bool isHdrEnabled;

  CameraState({
    this.controller,
    this.isInitialized = false,
    this.cameras = const [],
    this.selectedCameraIndex = 0,
    this.zoomLevel = 1.0,
    this.error,
    this.flashMode = FlashMode.off,
    this.timerDuration = Duration.zero,
    this.aspectRatio = '3:4',
    this.isHdrEnabled = false,
  });

  CameraState copyWith({
    CameraController? controller,
    bool? isInitialized,
    List<CameraDescription>? cameras,
    int? selectedCameraIndex,
    double? zoomLevel,
    String? error,
    FlashMode? flashMode,
    Duration? timerDuration,
    String? aspectRatio,
    bool? isHdrEnabled,
  }) {
    return CameraState(
      controller: controller ?? this.controller,
      isInitialized: isInitialized ?? this.isInitialized,
      cameras: cameras ?? this.cameras,
      selectedCameraIndex: selectedCameraIndex ?? this.selectedCameraIndex,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      error: error ?? this.error,
      flashMode: flashMode ?? this.flashMode,
      timerDuration: timerDuration ?? this.timerDuration,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      isHdrEnabled: isHdrEnabled ?? this.isHdrEnabled,
    );
  }
}

class CameraNotifier extends StateNotifier<CameraState> {
  CameraNotifier() : super(CameraState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        state = state.copyWith(error: 'No cameras found');
        return;
      }
      state = state.copyWith(cameras: cameras);
      await _initController(cameras[state.selectedCameraIndex]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _initController(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup
                .nv21 // ML Kit handles NV21 well on Android
          : ImageFormatGroup.bgra8888,
    );

    try {
      await controller.initialize();
      state = state.copyWith(
        controller: controller,
        isInitialized: true,
        zoomLevel: 1.0,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> switchCamera() async {
    if (state.cameras.length < 2) return;

    final nextIndex = (state.selectedCameraIndex + 1) % state.cameras.length;
    state = state.copyWith(
      isInitialized: false,
      selectedCameraIndex: nextIndex,
      zoomLevel: 1.0,
    );

    await state.controller?.dispose();
    await _initController(state.cameras[nextIndex]);
  }

  Future<XFile?> takePicture() async {
    if (state.controller == null || !state.isInitialized) return null;
    if (state.controller!.value.isTakingPicture) return null;

    try {
      final XFile file = await state.controller!.takePicture();
      return file;
    } catch (e) {
      debugPrint('Error taking picture: $e');
      return null;
    }
  }

  Future<void> setZoom(double zoom) async {
    if (state.controller == null || !state.isInitialized) return;
    try {
      final maxZoom = await state.controller!.getMaxZoomLevel();
      final minZoom = await state.controller!.getMinZoomLevel();
      final targetZoom = zoom.clamp(minZoom, maxZoom);
      await state.controller!.setZoomLevel(targetZoom);
      state = state.copyWith(zoomLevel: targetZoom);
    } catch (e) {
      debugPrint('Error setting zoom: $e');
    }
  }

  /// Smart Zoom: Now immediate for faster feedback
  Future<void> smartZoom(double targetZoom) async {
    if (state.controller == null || !state.isInitialized) return;
    await setZoom(targetZoom);
  }

  /// Set exposure compensation (EV) if supported
  Future<void> setExposure(double ev) async {
    if (state.controller == null || !state.isInitialized) return;
    try {
      final clamped = ev.clamp(
        state.controller!.description.lensDirection == CameraLensDirection.back
            ? -2.0
            : -1.5,
        2.0,
      );
      await state.controller!.setExposureOffset(clamped);
    } catch (e) {
      debugPrint('Exposure control not supported: $e');
    }
  }

  Future<void> setExposureFromTap(double normalized) async {
    if (state.controller == null || !state.isInitialized) return;
    try {
      final minOffset = await state.controller!.getMinExposureOffset();
      final maxOffset = await state.controller!.getMaxExposureOffset();
      final targetOffset = lerpDouble(minOffset, maxOffset, normalized) ?? 0.0;
      await state.controller!.setExposureOffset(
        targetOffset.clamp(minOffset, maxOffset),
      );
    } catch (e) {
      debugPrint('Error setting exposure from tap: $e');
    }
  }

  /// Auto exposure lock
  Future<void> setAutoExposure(bool lock) async {
    if (state.controller == null || !state.isInitialized) return;
    try {
      await state.controller!.setExposureMode(
        lock ? ExposureMode.locked : ExposureMode.auto,
      );
    } catch (e) {
      debugPrint('Auto exposure not supported: $e');
    }
  }

  Future<void> lockFocusAndExposure() async {
    if (state.controller == null || !state.isInitialized) return;
    try {
      await state.controller!.setFocusMode(FocusMode.locked);
      await state.controller!.setExposureMode(ExposureMode.locked);
    } catch (e) {
      debugPrint('Error locking focus/exposure: $e');
    }
  }

  Future<void> resetFocusAndExposure() async {
    if (state.controller == null || !state.isInitialized) return;
    try {
      await state.controller!.setFocusMode(FocusMode.auto);
      await state.controller!.setExposureMode(ExposureMode.auto);
    } catch (e) {
      debugPrint('Error resetting focus/exposure: $e');
    }
  }

  /// Toggle flash: Off -> Auto -> Always (On) -> Off
  Future<void> toggleFlash() async {
    if (state.controller == null || !state.isInitialized) return;
    
    final newMode = state.flashMode == FlashMode.off
        ? FlashMode.auto
        : state.flashMode == FlashMode.auto
            ? FlashMode.always
            : FlashMode.off;

    try {
      await state.controller!.setFlashMode(newMode);
      state = state.copyWith(flashMode: newMode);
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  /// Toggle HDR state
  Future<void> toggleHdr() async {
    state = state.copyWith(isHdrEnabled: !state.isHdrEnabled);
  }

  /// Set flash mode
  Future<void> setFlashMode(FlashMode mode) async {
    if (state.controller == null || !state.isInitialized) return;
    try {
      await state.controller!.setFlashMode(mode);
      state = state.copyWith(flashMode: mode);
    } catch (e) {
      debugPrint('Error setting flash mode: $e');
    }
  }

  /// Set timer duration
  Future<void> setTimer(Duration duration) async {
    state = state.copyWith(timerDuration: duration);
  }

  Future<void> setAspectRatio(String ratio) async {
    state = state.copyWith(aspectRatio: ratio);
  }

  void cycleAspectRatio() {
    const ratios = ['3:4', '1:1', '16:9', 'Full'];
    final currentIndex = ratios.indexOf(state.aspectRatio);
    final nextIndex = (currentIndex + 1) % ratios.length;
    state = state.copyWith(aspectRatio: ratios[nextIndex]);
  }

  @override
  void dispose() {
    state.controller?.dispose();
    super.dispose();
  }
}

final selfTimerProvider = StateProvider<int>(
  (ref) => 0,
); // Self-timer: 0, 3, 5, or 10 seconds
final countdownProvider = StateProvider<int>(
  (ref) => 0,
); // Active countdown seconds: 0 when inactive
