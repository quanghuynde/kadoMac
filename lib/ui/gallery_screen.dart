import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:project/services/database_service.dart';
import 'package:project/ui/photo_preview_screen.dart';
import 'package:project/utils/animation_config.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _refreshHistory();
  }

  void _refreshHistory() {
    setState(() {
      _historyFuture = DatabaseService().getPhotoHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tất cả',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn(
                    duration: AppAnimations.normal,
                    curve: AppAnimations.easeOut,
                  ).slideX(
                    begin: -0.1,
                    end: 0,
                    duration: AppAnimations.normal,
                    curve: AppAnimations.easeOutCubic,
                  ),
                  const SizedBox(), // Spacer
                ],
              ),
            ),

            // Grid of photos
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00FFCC),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Lỗi: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  final photos = snapshot.data ?? [];
                  if (photos.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white38,
                            size: 64,
                          ).animate().scaleXY(
                            begin: 0.8,
                            end: 1,
                            duration: AppAnimations.slow,
                            curve: AppAnimations.elasticOut,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Chưa có ảnh nào được chụp',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 15,
                            ),
                          ).animate().fadeIn(
                            duration: AppAnimations.normal,
                            curve: AppAnimations.easeOut,
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.75, // Matches typical vertical camera photo ratio
                    ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      final file = File(photo['path'] as String);
                      final hasImage = file.existsSync();

                      return GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PhotoPreviewScreen(
                                photos: photos,
                                initialIndex: index,
                              ),
                            ),
                          );
                          // Refresh gallery list if a photo was deleted or edited
                          if (result == true) {
                            _refreshHistory();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                              width: 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: hasImage
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(
                                      file,
                                      fit: BoxFit.cover,
                                    ),
                                    // Live preview matrix overlay if values are set
                                    _buildMatrixFilter(photo),
                                  ],
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.white24,
                                    size: 32,
                                  ),
                                ),
                        ),
                      ).animate().fadeIn(
                        duration: AppAnimations.normal,
                        delay: AppAnimations.staggerFast * (index % 12),
                        curve: AppAnimations.easeOut,
                      ).scaleXY(
                        begin: 0.9,
                        end: 1,
                        duration: AppAnimations.normal,
                        delay: AppAnimations.staggerFast * (index % 12),
                        curve: AppAnimations.easeOutCubic,
                      );
                    },
                  );
                },
              ),
            ),

            // Bottom Navigation Switcher
            Container(
              padding: const EdgeInsets.only(bottom: 24, top: 12),
              color: Colors.black,
              child: Center(
                child: Container(
                  height: 50,
                  width: 220,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      // Camera Option (Left tab)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            height: 42,
                            margin: const EdgeInsets.only(left: 4),
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                            ),
                            child: const Text(
                              'Máy ảnh',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Gallery Option (Right tab, Selected)
                      Expanded(
                        child: Container(
                          height: 42,
                          margin: const EdgeInsets.only(right: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(21),
                          ),
                          child: const Text(
                            'Thư viện',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(
                duration: AppAnimations.slow,
                curve: AppAnimations.easeOut,
              ).slideY(
                begin: 0.2,
                end: 0,
                duration: AppAnimations.slow,
                curve: AppAnimations.easeOutCubic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrixFilter(Map<String, dynamic> photo) {
    final double brightness = (photo['brightness'] as num?)?.toDouble() ?? 0.0;
    final double exposure = (photo['exposure'] as num?)?.toDouble() ?? 0.0;
    final double contrast = (photo['contrast'] as num?)?.toDouble() ?? 0.0;
    final double temp = (photo['temperature'] as num?)?.toDouble() ?? 0.0;
    final double sat = (photo['saturation'] as num?)?.toDouble() ?? 0.0;
    final double fade = (photo['fade'] as num?)?.toDouble() ?? 0.0;

    final hasEdits = brightness != 0.0 ||
        exposure != 0.0 ||
        contrast != 0.0 ||
        temp != 0.0 ||
        sat != 0.0 ||
        fade != 0.0;

    if (!hasEdits) return const SizedBox.shrink();

    // Reconstruct matrix logic
    final matrix = _calculateCombinedMatrix(
      brightness: brightness,
      exposure: exposure,
      contrast: contrast,
      temperature: temp,
      saturation: sat,
      fade: fade,
    );

    return Positioned.fill(
      child: ColorFiltered(
        colorFilter: ColorFilter.matrix(matrix),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  List<double> _calculateCombinedMatrix({
    required double brightness,
    required double exposure,
    required double contrast,
    required double temperature,
    required double saturation,
    required double fade,
  }) {
    // Start with identity matrix
    List<double> m = [
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ];

    // 1. Exposure (scale RGB factor: -1.0 to 1.0 -> 0.5 to 2.0 multiplier)
    double expScale = exposure >= 0 ? (1.0 + exposure) : (1.0 + exposure * 0.5);
    m[0] *= expScale;
    m[6] *= expScale;
    m[12] *= expScale;

    // 2. Brightness (offset RGB: -1.0 to 1.0 -> -100 to 100)
    double brOffset = brightness * 80;
    m[4] += brOffset;
    m[9] += brOffset;
    m[14] += brOffset;

    // 3. Contrast (factor around 1.0)
    if (contrast != 0) {
      double cFactor = contrast >= 0 ? (1.0 + contrast * 0.8) : (1.0 + contrast * 0.5);
      double offset = 128.0 * (1.0 - cFactor);
      
      // We perform matrix multiplication for contrast
      // R' = cFactor * R + offset
      m[0] *= cFactor;
      m[4] = m[4] * cFactor + offset;

      m[6] *= cFactor;
      m[9] = m[9] * cFactor + offset;

      m[12] *= cFactor;
      m[14] = m[14] * cFactor + offset;
    }

    // 4. Color Temperature (Temperature: -1.0 to 1.0)
    // Warm: increase red/green offset, Cool: increase blue offset
    if (temperature != 0) {
      double tempShift = temperature * 30;
      m[4] += tempShift;         // Red offset
      m[9] += tempShift * 0.5;   // Green offset
      m[14] -= tempShift;        // Blue offset
    }

    // 5. Saturation (0.0 to 2.0)
    if (saturation != 0) {
      double sMult = saturation >= 0 ? (1.0 + saturation) : (1.0 + saturation * 0.8);
      double invS = 1.0 - sMult;
      double r = 0.2126 * invS;
      double g = 0.7152 * invS;
      double b = 0.0722 * invS;

      // Combined Row 0: coeff red
      double r1 = m[0], r2 = m[1], r3 = m[2], r4 = m[4];
      double g1 = m[5], g2 = m[6], g3 = m[7], g4 = m[9];
      double b1 = m[10], b2 = m[11], b3 = m[12], b4 = m[14];

      m[0] = r1 * (r + sMult) + g1 * g + b1 * b;
      m[1] = r2 * (r + sMult) + g2 * g + b2 * b;
      m[2] = r3 * (r + sMult) + g3 * g + b3 * b;
      m[4] = r4 * (r + sMult) + g4 * g + b4 * b;

      m[5] = r1 * r + g1 * (g + sMult) + b1 * b;
      m[6] = r2 * r + g2 * (g + sMult) + b2 * b;
      m[7] = r3 * r + g3 * (g + sMult) + b3 * b;
      m[9] = r4 * r + g4 * (g + sMult) + b4 * b;

      m[10] = r1 * r + g1 * g + b1 * (b + sMult);
      m[11] = r2 * r + g2 * g + b2 * (b + sMult);
      m[12] = r3 * r + g3 * g + b3 * (b + sMult);
      m[14] = r4 * r + g4 * g + b4 * (b + sMult);
    }

    // 6. Fade (0.0 to 1.0)
    if (fade > 0) {
      // Shakes contrast down and increases black level
      double fadeFactor = 1.0 - fade * 0.25;
      double fadeOffset = fade * 35;

      m[0] *= fadeFactor;
      m[4] = m[4] * fadeFactor + fadeOffset;

      m[6] *= fadeFactor;
      m[9] = m[9] * fadeFactor + fadeOffset;

      m[12] *= fadeFactor;
      m[14] = m[14] * fadeFactor + fadeOffset;
    }

    return m;
  }
}
