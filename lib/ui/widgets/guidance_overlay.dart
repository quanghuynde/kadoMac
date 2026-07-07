import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project/providers/ai_coach_provider.dart';
import 'package:project/providers/camera_provider.dart';
import 'package:project/providers/sensor_provider.dart';
import 'package:project/providers/settings_provider.dart';
import 'package:project/ui/widgets/overlay_painter.dart';

class GuidanceOverlay extends ConsumerStatefulWidget {
  const GuidanceOverlay({super.key});

  @override
  ConsumerState<GuidanceOverlay> createState() => _GuidanceOverlayState();
}

class _GuidanceOverlayState extends ConsumerState<GuidanceOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scanningController;
  late Animation<double> _scanningAnimation;
  late AnimationController _frameLockController;
  late Animation<double> _frameLockAnimation;

  @override
  void initState() {
    super.initState();
    _scanningController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanningAnimation = CurvedAnimation(
      parent: _scanningController,
      curve: Curves.easeInOut,
    );
    _scanningController.repeat();

    _frameLockController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _frameLockAnimation = CurvedAnimation(
      parent: _frameLockController,
      curve: Curves.easeOutQuart,
    );
  }

  @override
  void dispose() {
    _scanningController.dispose();
    _frameLockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiCoachProvider);
    final horizonAngle = ref.watch(sensorProvider).value ?? 0.0;
    final settings = ref.watch(settingsProvider);
    final cameraState = ref.watch(cameraProvider);

    // Start/stop scanning animation based on status
    if (aiState.status == AICoachStatus.scanning) {
      _scanningController.repeat();
    } else {
      _scanningController.stop();
    }

    // Reset frame-lock animation when transitioning out of detection states
    if (aiState.status == AICoachStatus.idle || aiState.status == AICoachStatus.scanning) {
      if (_frameLockController.value > 0 && !_frameLockController.isAnimating) {
        _frameLockController.reset();
        // Reset zoom if it was zoomed by coach (optional, but keep for consistency if zoom was desired)
        // ref.read(cameraProvider.notifier).setZoom(1.0);
      }
    }

    // Play frame-lock animation when almost aligned
    if (aiState.status == AICoachStatus.almostThere &&
        !_frameLockController.isAnimating && _frameLockController.value == 0) {
      _frameLockController.forward();
    }

    final sensorOrientation =
        cameraState.isInitialized && cameraState.cameras.isNotEmpty
        ? cameraState.cameras[cameraState.selectedCameraIndex].sensorOrientation
        : 90;
    final isFrontCamera =
        cameraState.isInitialized && cameraState.cameras.isNotEmpty
        ? cameraState.cameras[cameraState.selectedCameraIndex].lensDirection ==
              CameraLensDirection.front
        : false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        return AnimatedBuilder(
          animation: Listenable.merge([_scanningAnimation, _frameLockAnimation]),
          builder: (context, child) {
            final progress = _frameLockAnimation.value;
            
            // Define the clip rect based on the framing box
            // Using dynamic frame if available, otherwise fallback to default
            final targetFrame = aiState.aiSuggestedFrame;
            final center = aiState.aiSuggestedCenter != null 
              ? _translateOffset(aiState.aiSuggestedCenter!, viewportSize, aiState.result.imageSize, sensorOrientation, isFrontCamera)
              : Offset(viewportSize.width / 2, viewportSize.height / 2);
            
            final double initialSize = 80.0;
            final double finalWidth = targetFrame != null 
              ? _translateX(targetFrame.width, viewportSize, aiState.result.imageSize, sensorOrientation)
              : 240.0;
            final double finalHeight = targetFrame != null 
              ? _translateY(targetFrame.height, viewportSize, aiState.result.imageSize, sensorOrientation)
              : 240.0;

            final currentWidth = initialSize + (finalWidth - initialSize) * progress;
            final currentHeight = initialSize + (finalHeight - initialSize) * progress;

            return Stack(
              fit: StackFit.expand,
              children: [
                // Viewport Mask (Darkens the area outside the framing box)
                if (progress > 0)
                  ClipPath(
                    clipper: InvertedRectClipper(
                      center: center,
                      width: currentWidth,
                      height: currentHeight,
                      borderRadius: 24.0,
                    ),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.95 * progress),
                    ),
                  ),
                
                CustomPaint(
                  size: Size.infinite,
                  painter: OverlayPainter(
                    result: aiState.displayResult,
                    horizonAngle: horizonAngle,
                    showGrid: settings.showGrid,
                    status: aiState.status,
                    sensorOrientation: sensorOrientation,
                    isFrontCamera: isFrontCamera,
                    aiSuggestedFrame: aiState.aiSuggestedFrame,
                    aiSuggestedCenter: aiState.aiSuggestedCenter,
                    scanningProgress: _scanningAnimation.value,
                    frameLockProgress: _frameLockAnimation.value,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  double _translateX(double x, Size canvasSize, Size imageSize, int sensorOrientation) {
    if (imageSize == Size.zero) return x;
    if (sensorOrientation == 90 || sensorOrientation == 270) {
      return x * canvasSize.width / imageSize.height;
    } else {
      return x * canvasSize.width / imageSize.width;
    }
  }

  double _translateY(double y, Size canvasSize, Size imageSize, int sensorOrientation) {
    if (imageSize == Size.zero) return y;
    if (sensorOrientation == 90 || sensorOrientation == 270) {
      return y * canvasSize.height / imageSize.width;
    } else {
      return y * canvasSize.height / imageSize.height;
    }
  }

  // Duplicate coordinate translation logic to calculate clip center
  Offset _translateOffset(Offset offset, Size canvasSize, Size imageSize, int sensorOrientation, bool isFrontCamera) {
    if (imageSize == Size.zero) return offset;
    double calculatedX = _translateX(offset.dx, canvasSize, imageSize, sensorOrientation);
    double calculatedY = _translateY(offset.dy, canvasSize, imageSize, sensorOrientation);

    if (isFrontCamera) {
      calculatedX = canvasSize.width - calculatedX;
    }
    
    return Offset(calculatedX, calculatedY);
  }
}

class InvertedRectClipper extends CustomClipper<Path> {
  final Offset center;
  final double width;
  final double height;
  final double borderRadius;

  InvertedRectClipper({
    required this.center,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  Path getClip(Size size) {
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final holeRect = Rect.fromCenter(center: center, width: this.width, height: this.height);
    final holePath = Path()..addRRect(RRect.fromRectAndRadius(holeRect, Radius.circular(borderRadius)));
    
    return Path.combine(PathOperation.difference, path, holePath);
  }

  @override
  bool shouldReclip(covariant InvertedRectClipper oldClipper) => 
    center != oldClipper.center || width != oldClipper.width || height != oldClipper.height || borderRadius != oldClipper.borderRadius;
}
