import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cameraProvider = StateNotifierProvider<CameraNotifier, CameraState>((ref) {
  return CameraNotifier();
});

class CameraState {
  final CameraController? controller;
  final bool isInitialized;
  final List<CameraDescription> cameras;
  final int selectedCameraIndex;
  final String? error;

  CameraState({
    this.controller,
    this.isInitialized = false,
    this.cameras = const [],
    this.selectedCameraIndex = 0,
    this.error,
  });

  CameraState copyWith({
    CameraController? controller,
    bool? isInitialized,
    List<CameraDescription>? cameras,
    int? selectedCameraIndex,
    String? error,
  }) {
    return CameraState(
      controller: controller ?? this.controller,
      isInitialized: isInitialized ?? this.isInitialized,
      cameras: cameras ?? this.cameras,
      selectedCameraIndex: selectedCameraIndex ?? this.selectedCameraIndex,
      error: error ?? this.error,
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
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid 
          ? ImageFormatGroup.nv21 // ML Kit handles NV21 well on Android
          : ImageFormatGroup.bgra8888,
    );

    try {
      await controller.initialize();
      state = state.copyWith(
        controller: controller,
        isInitialized: true,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> switchCamera() async {
    if (state.cameras.length < 2) return;
    
    final nextIndex = (state.selectedCameraIndex + 1) % state.cameras.length;
    state = state.copyWith(isInitialized: false, selectedCameraIndex: nextIndex);
    
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
    } catch (e) {
      debugPrint('Error setting zoom: $e');
    }
  }

  @override
  void dispose() {
    state.controller?.dispose();
    super.dispose();
  }
}
