import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project/models/filter_model.dart';
import 'package:project/providers/ai_coach_provider.dart';
import 'package:project/providers/camera_provider.dart';
import 'package:project/services/filter_engine.dart';
import 'package:project/services/image_crop_service.dart';
import 'package:project/ui/gallery_screen.dart';
import 'package:project/ui/result_screen.dart';
import 'package:project/utils/animation_config.dart';
import 'package:project/providers/settings_provider.dart';

class CameraBottomControls extends ConsumerStatefulWidget {
  final VoidCallback? onShutter;

  const CameraBottomControls({super.key, this.onShutter});

  @override
  ConsumerState<CameraBottomControls> createState() => _CameraBottomControlsState();
}

class _CameraBottomControlsState extends ConsumerState<CameraBottomControls> {
  bool _showThemes = false;
  double _exposureValue = 100.0;

  Future<void> _triggerCapture(BuildContext context, WidgetRef ref) async {
    final aiState = ref.read(aiCoachProvider);
    final currentFilter = FilterEngine.instance.currentFilter;
    
    // Call UI shutter effect
    widget.onShutter?.call();

    final xFile = await ref.read(cameraProvider.notifier).takePicture();
    if (xFile == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể chụp ảnh')));
      }
      return;
    }

    File imageFile = File(xFile.path);

    // Get frame info for cropping if fully locked
    Rect? cropRect;
    if (aiState.status == AICoachStatus.almostThere && aiState.aiSuggestedCenter != null && aiState.aiSuggestedFrame != null) {
      cropRect = Rect.fromCenter(
        center: aiState.aiSuggestedCenter!,
        width: aiState.aiSuggestedFrame!.width,
        height: aiState.aiSuggestedFrame!.height,
      );
    }

    // Process image: Apply Theme + Crop
    await ImageCropService.applyFilterAndCrop(
      imageFile,
      colorMatrix: currentFilter.id != 'original' ? currentFilter.colorMatrix : null,
      cropRect: cropRect,
      analysisImageSize: aiState.result.imageSize,
    );

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          imagePath: imageFile.path,
          result: aiState.result,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiCoachProvider);
    final cameraState = ref.watch(cameraProvider);

    if (cameraState.controller == null || !cameraState.isInitialized) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showThemes) ...[
            // Exposure Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                        overlayColor: Colors.white.withValues(alpha: 0.1),
                        trackHeight: 1,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: _exposureValue,
                        min: 0,
                        max: 200,
                        onChanged: (val) {
                          setState(() => _exposureValue = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _exposureValue.toInt().toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            
            // Theme Control Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Cuộn phim',
                      style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showThemes = false),
                    child: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 28),
                  ),
                ],
              ),
            ),

            // Theme Selector List
            SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Clear Filter Button
                  _ClearFilterItem(
                    onTap: () {
                      FilterEngine.instance.reset();
                      setState(() => _showThemes = false);
                    },
                  ),
                  
                  // Film Theme Items
                  ...FilterPreset.all.where((f) => f.id != 'original').map((filter) {
                    final isActive = FilterEngine.instance.currentFilter.id == filter.id;
                    return _ThemeStripItem(
                      filter: filter,
                      isActive: isActive,
                      onTap: () {
                        FilterEngine.instance.setFilter(filter);
                        setState(() => _showThemes = false);
                      },
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Row 1: Grid, Aspect Ratio, Flip
          if (!_showThemes)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _IconActionButton(
                    icon: Icons.grid_4x4,
                    onTap: () {
                      final settings = ref.read(settingsProvider);
                      ref.read(settingsProvider.notifier).setShowGrid(!settings.showGrid);
                    },
                    isActive: ref.watch(settingsProvider).showGrid,
                  ),
                  _LabelActionButton(
                    label: ref.watch(cameraProvider).aspectRatio,
                    onTap: () => ref.read(cameraProvider.notifier).cycleAspectRatio(),
                  ),
                  _IconActionButton(
                    icon: Icons.sync,
                    onTap: () => ref.read(cameraProvider.notifier).switchCamera(),
                  ),
                ],
              ),
            ),

          // Row 2: Gallery/Theme, Shutter, AI Scan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!_showThemes)
                  _ThemeSwitcherButton(
                    onTap: () => setState(() => _showThemes = true),
                  )
                else
                  const SizedBox(width: 54),
                
                _ShutterButton(
                  onTap: () => _triggerCapture(context, ref),
                ),
                
                if (!_showThemes)
                  _AIScanButton(
                    isEnabled: aiState.isEnabled,
                    onTap: () => ref.read(aiCoachProvider.notifier).toggleEnabled(),
                  )
                else
                  const SizedBox(width: 54),
              ],
            ),
          ),

          if (!_showThemes) ...[
            const SizedBox(height: 30),
            const _ModeSwitcher(),
          ],
        ],
      ),
    );
  }
}

class _ThemeStripItem extends StatelessWidget {
  final FilterPreset filter;
  final bool isActive;
  final VoidCallback onTap;

  const _ThemeStripItem({
    required this.filter,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final descriptions = {
      'cc': 'Đường phố, kết cấu',
      'cn': 'Chất lượng điện ảnh',
      '160c': 'Chân dung tự nhiên',
      'superia100': 'Thường nhật, tinh tế',
      '400hh': 'Phong cảnh ngoài trời',
      '400hs': 'Thiên nhiên ánh sáng yếu',
      'vista800': 'Đường phố ngoài trời',
    };

    // Curated aesthetic network images for previews
    final previewImages = {
      'cc': 'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=200&q=80', // City
      'cn': 'https://images.unsplash.com/photo-1485846234645-a62644f84728?w=200&q=80', // Cinema
      '160c': 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=200&q=80', // Portrait
      'superia100': 'https://images.unsplash.com/photo-1541480601022-2308c0f02487?w=200&q=80', // Still life
      '400hh': 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=200&q=80', // Landscape
      '400hs': 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=200&q=80', // Nature
      'vista800': 'https://images.unsplash.com/photo-1517732359359-51f709b11ef0?w=200&q=80', // Street night
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: Colors.white, width: 1.5) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.black26,
                  image: DecorationImage(
                    image: NetworkImage(previewImages[filter.id] ?? 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=200&q=80'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0, top: 0, bottom: 0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (_) => Container(width: 4, height: 4, color: Colors.black45)),
                      ),
                    ),
                    Positioned(
                      right: 0, top: 0, bottom: 0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (_) => Container(width: 4, height: 4, color: Colors.black45)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 14, height: 18,
                        decoration: BoxDecoration(
                          color: filter.swatchColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        filter.name,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descriptions[filter.id] ?? '',
                    style: const TextStyle(color: Colors.white54, fontSize: 8),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearFilterItem extends StatelessWidget {
  final VoidCallback onTap;

  const _ClearFilterItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white12,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            const Text(
              'Xóa',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSwitcherButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ThemeSwitcherButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white10,
          border: Border.all(color: Colors.white38, width: 1.5),
        ),
        child: const Icon(
          Icons.auto_awesome_motion_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _IconActionButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        color: isActive ? const Color(0xFF00FFCC) : Colors.white,
        size: 26,
      ),
    );
  }
}

class _LabelActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LabelActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ShutterButton extends StatefulWidget {
  final VoidCallback onTap;

  const _ShutterButton({required this.onTap});

  @override
  State<_ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<_ShutterButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ).animate().scaleXY(
        begin: _isPressed ? 1.0 : 0.92,
        end: _isPressed ? 0.92 : 1.0,
        duration: AppAnimations.fast,
        curve: AppAnimations.easeOutCubic,
      ),
    );
  }
}

class _AIScanButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onTap;

  const _AIScanButton({required this.isEnabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.center_focus_weak,
            color: isEnabled ? const Color(0xFF00FFCC) : Colors.white,
            size: 30,
          ),
          const SizedBox(height: 4),
          Text(
            'Quét AI',
            style: TextStyle(
              color: isEnabled ? const Color(0xFF00FFCC) : Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSwitcher extends ConsumerWidget {
  const _ModeSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 200,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Center(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Center(
                    child: Text(
                      'Máy ảnh',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GalleryScreen()),
              ),
              child: const Center(
                child: Text(
                  'Bộ sưu tập',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
