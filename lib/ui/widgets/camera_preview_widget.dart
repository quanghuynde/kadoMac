import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:project/providers/camera_provider.dart';
import 'package:project/providers/ai_coach_provider.dart';
import 'package:project/providers/camera_tap_provider.dart';
import 'package:project/services/filter_engine.dart';

class CameraPreviewWidget extends ConsumerStatefulWidget {
  const CameraPreviewWidget({super.key});

  @override
  ConsumerState<CameraPreviewWidget> createState() =>
      _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends ConsumerState<CameraPreviewWidget> {
  double _baseZoom = 1.0;
  double _lastScale = 1.0;

  @override
  void initState() {
    super.initState();
    FilterEngine.instance.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    FilterEngine.instance.removeListener(_onFilterChanged);
    super.dispose();
  }

  void _onFilterChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraProvider);
    ref.watch(aiCoachProvider);

    if (!cameraState.isInitialized || cameraState.controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Get the preview size and calculate aspect ratio
    final size = MediaQuery.of(context).size;
    
    // Map aspectRatio string to double
    double targetRatio;
    switch (cameraState.aspectRatio) {
      case '1:1':
        targetRatio = 1.0;
        break;
      case '16:9':
        targetRatio = 9 / 16;
        break;
      case 'Full':
        targetRatio = size.aspectRatio;
        break;
      case '3:4':
      default:
        targetRatio = 3 / 4;
        break;
    }

    var scale = size.aspectRatio * cameraState.controller!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    Widget previewChild = Transform.scale(
      scale: scale,
      child: Center(
        child: AspectRatio(
          aspectRatio: targetRatio,
          child: CameraPreview(cameraState.controller!),
        ),
      ),
    );

    // Apply Filter Preset
    previewChild = ColorFiltered(
      colorFilter: FilterEngine.instance.colorFilter,
      child: previewChild,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) async {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) return;
        final localPos = renderBox.globalToLocal(details.globalPosition);
        final normalized = 1.0 - (localPos.dy / renderBox.size.height);
        ref.read(cameraTapProvider.notifier).state = localPos;
        await ref
            .read(cameraProvider.notifier)
            .setExposureFromTap(normalized.clamp(0.0, 1.0));
        HapticFeedback.lightImpact();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            ref.read(cameraTapProvider.notifier).state = null;
          }
        });
      },
      onScaleStart: (details) {
        _baseZoom = cameraState.zoomLevel;
        _lastScale = 1.0;
        ref.read(cameraTapProvider.notifier).state = null;
      },
      onScaleUpdate: (details) {
        if ((details.scale - _lastScale).abs() < 0.02) return;
        _lastScale = details.scale;

        final newZoom = _baseZoom * details.scale;
        ref.read(cameraProvider.notifier).setZoom(newZoom);
      },
      child: RepaintBoundary(child: previewChild),
    );
  }
}
