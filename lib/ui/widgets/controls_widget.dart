import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project/providers/ai_coach_provider.dart';
import 'package:project/providers/camera_provider.dart';
import 'package:project/providers/auth_provider.dart';
import 'package:project/ui/result_screen.dart';

import 'package:project/services/database_service.dart';

import 'package:project/ui/profile_screen.dart';

class ControlsWidget extends ConsumerWidget {
  const ControlsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(aiCoachProvider);

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom Selector
          const _ZoomSelector(),
          
          const SizedBox(height: 25),
          
          // Main Controls Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Gallery Icon
                IconButton(
                  icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 28),
                  onPressed: () {},
                ),
                
                // Capture Button
                _CaptureButton(onCapture: () async {
                  final file = await ref.read(cameraProvider.notifier).takePicture();
                  if (file != null && context.mounted) {
                    final aiResult = ref.read(aiCoachProvider);
                    await DatabaseService().savePhoto(
                      path: file.path,
                      result: aiResult.result,
                      tags: aiResult.tags,
                    );

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultScreen(
                            imagePath: file.path,
                            result: aiResult.result,
                          ),
                        ),
                      );
                    }
                  }
                }),
                
                // AI Toggle Switch (High Contrast)
                GestureDetector(
                  onTap: () => ref.read(aiCoachProvider.notifier).toggleEnabled(),
                  child: Column(
                    children: [
                      Icon(
                        aiState.isEnabled ? Icons.auto_awesome : Icons.auto_awesome_outlined,
                        color: aiState.isEnabled ? const Color(0xFF00FFCC) : Colors.white38,
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        aiState.isEnabled ? "BẬT AI" : "TẮT AI",
                        style: TextStyle(
                          color: aiState.isEnabled ? const Color(0xFF00FFCC) : Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomSelector extends ConsumerWidget {
  const _ZoomSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoomLevels = [0.5, 1, 2, 4, 8];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: zoomLevels.map((z) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: GestureDetector(
          onTap: () => ref.read(cameraProvider.notifier).setZoom(z.toDouble()),
          child: Text(
            z == 1 ? "1" : (z < 1 ? ".5" : "${z}x"),
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      )).toList(),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final VoidCallback onCapture;
  const _CaptureButton({required this.onCapture});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCapture,
      child: Container(
        height: 70,
        width: 70,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final bool isActive;
  const _NavItem({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: isActive ? Colors.white : Colors.white38,
        fontSize: 14,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
