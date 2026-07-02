import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project/providers/camera_provider.dart';

class CameraPreviewWidget extends ConsumerWidget {
  const CameraPreviewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraProvider);

    if (!cameraState.isInitialized || cameraState.controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RepaintBoundary(
      child: CameraPreview(cameraState.controller!),
    );
  }
}
