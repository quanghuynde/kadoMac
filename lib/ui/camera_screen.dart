import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project/providers/camera_provider.dart';
import 'package:project/ui/widgets/camera_preview_widget.dart';
import 'package:project/ui/widgets/guidance_overlay.dart';
import 'package:project/ui/widgets/controls_widget.dart';

class CameraScreen extends ConsumerWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Camera Viewport
          const Expanded(
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreviewWidget(),
                  GuidanceOverlay(),
                ],
              ),
            ),
          ),
          
          // Controls Area
          const ControlsWidget(),
        ],
      ),
    );
  }
}
