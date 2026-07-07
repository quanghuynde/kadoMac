import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project/providers/camera_provider.dart';
import 'package:project/utils/animation_config.dart';

class ZoomControls extends ConsumerWidget {
  const ZoomControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraProvider);
    final notifier = ref.read(cameraProvider.notifier);

    if (!cameraState.isInitialized || cameraState.controller == null) {
      return const SizedBox.shrink();
    }

    // Zoom presets: 1.0x / 2x / 3x
    const zoomPresets = [1.0, 2.0, 3.0];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...zoomPresets.map((zoom) {
            final isActive = (cameraState.zoomLevel - zoom).abs() < 0.05;
            return _ZoomLevelButton(
              zoom: zoom,
              isActive: isActive,
              onTap: () => notifier.setZoom(zoom),
            );
          }),
        ],
      ),
    );
  }
}

class _ZoomLevelButton extends StatefulWidget {
  final double zoom;
  final bool isActive;
  final VoidCallback onTap;

  const _ZoomLevelButton({
    required this.zoom,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_ZoomLevelButton> createState() => _ZoomLevelButtonState();
}

class _ZoomLevelButtonState extends State<_ZoomLevelButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final String label = widget.zoom == 1.0 ? '1.0x' : '${widget.zoom.toInt()}x';

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Container(
        width: 44,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.isActive
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: widget.isActive ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ).animate().scaleXY(
        begin: _isPressed ? 1.0 : 0.9,
        end: _isPressed ? 0.9 : 1.0,
        duration: AppAnimations.fast,
        curve: AppAnimations.easeOutCubic,
      ),
    );
  }
}
