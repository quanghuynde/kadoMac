import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project/providers/ai_coach_provider.dart';
import 'package:project/ui/widgets/camera_preview_widget.dart';
import 'package:project/ui/widgets/guidance_overlay.dart';
import 'package:project/ui/widgets/controls_widget.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiCoachProvider.notifier).enable();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Camera Viewport
          const Expanded(
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [CameraPreviewWidget(), GuidanceOverlay()],
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
