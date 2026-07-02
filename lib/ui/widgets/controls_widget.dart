import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project/providers/ai_coach_provider.dart';
import 'package:project/providers/camera_provider.dart';
import 'package:project/ui/photo_preview_screen.dart';
import 'package:project/ui/result_screen.dart';
import 'package:project/services/database_service.dart';

class ControlsWidget extends ConsumerWidget {
  const ControlsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(aiCoachProvider);

    final statusText = aiState.isEnabled
        ? _statusLabel(aiState.status)
        : 'AI TẮT';

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom Selector
          const _ZoomSelector(),

          const SizedBox(height: 12),

          // AI Status
          Text(
            statusText,
            style: const TextStyle(
              color: Color(0xFF00FFCC),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Main Controls Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Gallery Icon
                GestureDetector(
                  onTap: () async {
                    final history = await DatabaseService().getPhotoHistory();
                    if (history.isNotEmpty && context.mounted) {
                      final last = history.first;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PhotoPreviewScreen(
                            imagePath: last['path'] as String,
                            score: (last['overall_score'] as num).toDouble(),
                            compositionScore: (last['composition_score'] as num)
                                .toDouble(),
                            instruction: last['instruction'] as String,
                            tags: (last['tags'] as String).isEmpty
                                ? []
                                : (last['tags'] as String).split(','),
                          ),
                        ),
                      );
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chưa có ảnh đã chụp')),
                      );
                    }
                  },
                  child: Container(
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38, width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.photo_library_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),

                // Capture Button
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 110,
                      width: 110,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0xFF00FFCC), Colors.transparent],
                          stops: [0.2, 1.0],
                        ),
                      ),
                    ),
                    Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                    ),
                    _CaptureButton(
                      onCapture: () async {
                        final file = await ref
                            .read(cameraProvider.notifier)
                            .takePicture();
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
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Không thể chụp ảnh.'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),

                // AI button
                _ControlCircleButton(
                  icon: aiState.isEnabled
                      ? Icons.auto_awesome
                      : Icons.auto_awesome_outlined,
                  active: aiState.isEnabled,
                  onTap: () =>
                      ref.read(aiCoachProvider.notifier).toggleEnabled(),
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
      children: zoomLevels
          .map(
            (z) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GestureDetector(
                onTap: () =>
                    ref.read(cameraProvider.notifier).setZoom(z.toDouble()),
                child: Text(
                  z == 1 ? "1" : (z < 1 ? ".5" : "${z}x"),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          )
          .toList(),
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
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.35),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
          ),
          child: const Center(
            child: Icon(Icons.camera_alt, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

class _ControlCircleButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ControlCircleButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        width: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? const Color(0xFF00FFCC) : Colors.white24,
            width: 2,
          ),
          gradient: active
              ? const RadialGradient(
                  colors: [Color(0xFF00FFCC), Colors.transparent],
                  stops: [0.0, 1.0],
                )
              : null,
        ),
        child: Center(
          child: Icon(
            icon,
            color: active ? const Color(0xFF00FFCC) : Colors.white38,
            size: 28,
          ),
        ),
      ),
    );
  }
}

String _statusLabel(AICoachStatus status) {
  switch (status) {
    case AICoachStatus.guiding:
      return 'AI: Hướng dẫn căn chỉnh';
    case AICoachStatus.finished:
      return 'AI: Sẵn sàng chụp';
    case AICoachStatus.adjusted:
      return 'AI: Đã điều chỉnh';
    case AICoachStatus.analyzing:
      return 'AI: Đang phân tích';
  }
}
