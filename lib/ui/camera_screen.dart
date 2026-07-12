import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project/providers/ai_coach_provider.dart';
import 'package:project/ui/widgets/camera_preview_widget.dart';
import 'package:project/ui/widgets/guidance_overlay.dart';
import 'package:project/ui/widgets/camera_bottom_controls.dart';
import 'package:project/ui/widgets/zoom_controls.dart';
import 'package:project/providers/camera_provider.dart';
import 'package:project/utils/animation_config.dart';
import 'package:project/ui/settings_screen.dart';
import 'package:camera/camera.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  bool _showShutterFlash = false;

  void _triggerShutterFlash() {
    setState(() => _showShutterFlash = true);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _showShutterFlash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(aiCoachProvider);
    final cameraState = ref.watch(cameraProvider);
    final flashMode = cameraState.flashMode;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              // Top portion: Viewfinder area
              Expanded(
                child: Stack(
                  children: [
                    // Viewfinder Container with rounded corners
                    Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 10,
                        left: 12,
                        right: 12,
                        bottom: 10,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: Stack(
                          children: [
                            const CameraPreviewWidget(),
                            const GuidanceOverlay(),
                            
                            // Visual Shutter Flash
                            if (_showShutterFlash)
                              Container(color: Colors.white),
                          ],
                        ),
                      ),
                    ),

                    // Top Toolbar (matching screenshot)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 24,
                      left: 32,
                      right: 32,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Timer Button
                          GestureDetector(
                            onTap: () {
                              final current = ref.read(selfTimerProvider);
                              // Cycle: 0 -> 3 -> 5 -> 10 -> 0
                              final next = current == 0 ? 3 : current == 3 ? 5 : current == 5 ? 10 : 0;
                              ref.read(selfTimerProvider.notifier).state = next;
                            },
                            child: Row(
                              children: [
                                Icon(
                                  ref.watch(selfTimerProvider) == 0 ? Icons.timer_off_outlined : Icons.timer_outlined,
                                  color: ref.watch(selfTimerProvider) == 0 ? Colors.white : Colors.amber,
                                  size: 22,
                                ),
                                if (ref.watch(selfTimerProvider) > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Text(
                                      '${ref.watch(selfTimerProvider)}s',
                                      style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Flash Button
                          GestureDetector(
                            onTap: () => ref.read(cameraProvider.notifier).toggleFlash(),
                            child: Icon(
                              flashMode == FlashMode.always 
                                  ? Icons.flash_on 
                                  : flashMode == FlashMode.auto
                                      ? Icons.flash_auto
                                      : Icons.flash_off,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),

                          // HDR Toggle
                          GestureDetector(
                            onTap: () => ref.read(cameraProvider.notifier).toggleHdr(),
                            child: Text(
                              'HDR',
                              style: TextStyle(
                                color: cameraState.isHdrEnabled ? Colors.amber : Colors.white, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 14,
                              ),
                            ),
                          ),
                          
                          // AI Scan Toggle (Scanner Icon)
                          _IconActionButton(
                            icon: Icons.filter_center_focus, 
                            onTap: () => ref.read(aiCoachProvider.notifier).toggleEnabled(),
                            color: ref.watch(aiCoachProvider).isEnabled ? Colors.amber : Colors.white,
                          ),

                          // Settings
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SettingsScreen()),
                            ),
                            child: const Icon(
                              Icons.menu,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Zoom Controls - floating at the bottom of the viewfinder
                    Positioned(
                      bottom: 30,
                      left: 0,
                      right: 0,
                      child: Center(child: const ZoomControls())
                          .animate()
                          .fadeIn(duration: AppAnimations.normal),
                    ),
                  ],
                ),
              ),

              // Bottom portion: Controls panel
              CameraBottomControls(
                onShutter: _triggerShutterFlash,
              ),
            ],
          ),

          // Self-timer countdown visual overlay (full screen)
          Consumer(
            builder: (context, ref, _) {
              final countdown = ref.watch(countdownProvider);
              if (countdown <= 0) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black38,
                child: Center(
                  child: Text(
                    '$countdown',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 120,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate(key: ValueKey(countdown)).scale(
                    begin: const Offset(1.8, 1.8),
                    end: const Offset(1.0, 1.0),
                    duration: 300.ms,
                  ).fadeOut(delay: 700.ms, duration: 200.ms),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _IconActionButton({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 22),
    );
  }
}
