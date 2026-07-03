import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project/providers/ai_coach_provider.dart';
import 'package:project/providers/camera_provider.dart';
import 'package:project/providers/sensor_provider.dart';
import 'package:project/services/capture_service.dart';
import 'package:project/services/database_service.dart';
import 'package:project/providers/settings_provider.dart';
import 'package:project/ui/photo_preview_screen.dart';
import 'package:project/ui/result_screen.dart';

class ControlsWidget extends ConsumerWidget {
  const ControlsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(aiCoachProvider);

    final statusText = aiState.isEnabled
        ? _statusLabel(aiState.status)
        : 'AI TẮT';

    final autoCaptureRequested = aiState.autoCaptureRequested;
    if (autoCaptureRequested) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleAutoCapture(ref, context);
      });
    }

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
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: aiState.autoCaptureEnabled
                      ? const Color(0xFF00FFCC)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: aiState.autoCaptureEnabled
                        ? const Color(0xFF00FFCC)
                        : Colors.white12,
                  ),
                ),
                child: GestureDetector(
                  onTap: () =>
                      ref.read(aiCoachProvider.notifier).toggleAutoCapture(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        aiState.autoCaptureEnabled
                            ? Icons.flash_auto
                            : Icons.flash_off,
                        size: 16,
                        color: aiState.autoCaptureEnabled
                            ? Colors.black
                            : Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        aiState.autoCaptureEnabled
                            ? 'Tự động chụp'
                            : 'Chạm để tự động',
                        style: TextStyle(
                          color: aiState.autoCaptureEnabled
                              ? Colors.black
                              : Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: aiState.status == AICoachStatus.finished ? 120 : 110,
                      width: aiState.status == AICoachStatus.finished ? 120 : 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            aiState.status == AICoachStatus.finished
                                ? const Color(0xFF00FFCC).withValues(alpha: 0.8)
                                : const Color(0xFF00FFCC),
                            Colors.transparent
                          ],
                          stops: const [0.2, 1.0],
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: aiState.status == AICoachStatus.finished
                              ? const Color(0xFF00FFCC)
                              : Colors.white24,
                          width: aiState.status == AICoachStatus.finished ? 3 : 2,
                        ),
                      ),
                    ),
                    _CaptureButton(
                      onCapture: () async {
                        final file = await ref
                            .read(cameraProvider.notifier)
                            .takePicture();
                        if (file == null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Không thể chụp ảnh.'),
                              ),
                            );
                          }
                          return;
                        }

                        final previewState = ref.read(aiCoachProvider);
                        final settings = ref.read(settingsProvider);
                        final captureResult =
                            await CaptureService.processCapture(
                              File(file.path),
                              previewState,
                              ref.read(sensorProvider).value ?? 0.0,
                              settings: settings,
                            );

                        await DatabaseService().savePhoto(
                          path: captureResult.imageFile.path,
                          result: captureResult.result,
                          tags: previewState.tags,
                        );

                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ResultScreen(
                                imagePath: captureResult.imageFile.path,
                                result: captureResult.result,
                              ),
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

  Future<void> _handleAutoCapture(WidgetRef ref, BuildContext context) async {
    final state = ref.read(aiCoachProvider);
    if (!state.autoCaptureRequested) return;

    ref.read(aiCoachProvider.notifier).clearAutoCaptureRequest();
    final file = await ref.read(cameraProvider.notifier).takePicture();
    if (file == null || !context.mounted) return;

    final settings = ref.read(settingsProvider);
    final captureResult = await CaptureService.processCapture(
      File(file.path),
      state,
      ref.read(sensorProvider).value ?? 0.0,
      settings: settings,
    );

    await DatabaseService().savePhoto(
      path: captureResult.imageFile.path,
      result: captureResult.result,
      tags: state.tags,
    );

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          imagePath: captureResult.imageFile.path,
          result: captureResult.result,
        ),
      ),
    );
  }
}

class _ZoomSelector extends ConsumerWidget {
  const _ZoomSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraProvider);
    final zoomLevels = [0.5, 1, 2, 4, 8];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: zoomLevels.map((z) {
        final isSelected = cameraState.zoomLevel == z;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutQuad,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color.fromRGBO(0, 255, 204, 0.18)
                  : Colors.white10,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? const Color(0xFF00FFCC) : Colors.white24,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: GestureDetector(
              onTap: () =>
                  ref.read(cameraProvider.notifier).setZoom(z.toDouble()),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 240),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: isSelected ? 14 : 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
                child: Text(z == 1 ? '1' : (z < 1 ? '.5' : '${z}x')),
              ),
            ),
          ),
        );
      }).toList(),
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
              color: const Color.fromRGBO(255, 255, 255, 0.35),
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
