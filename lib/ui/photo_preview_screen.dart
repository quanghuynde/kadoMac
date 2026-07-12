import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:project/services/database_service.dart';
import 'package:project/utils/animation_config.dart';
import 'package:gal/gal.dart';

class PhotoPreviewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> photos;
  final int initialIndex;

  const PhotoPreviewScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  late PageController _pageController;
  late int _currentIndex;

  // Edit states
  bool _isEditing = false;
  late double _brightness;
  late double _exposure;
  late double _contrast;
  late double _temperature;
  late double _saturation;
  late double _fade;

  // Temp values to revert if cancelled
  late double _tempBrightness = 0.0;
  late double _tempExposure = 0.0;
  late double _tempContrast = 0.0;
  late double _tempTemperature = 0.0;
  late double _tempSaturation = 0.0;
  late double _tempFade = 0.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadPhotoData(_currentIndex);
  }

  void _loadPhotoData(int index) {
    final data = widget.photos[index];
    setState(() {
      _brightness = (data['brightness'] as num?)?.toDouble() ?? 0.0;
      _exposure = (data['exposure'] as num?)?.toDouble() ?? 0.0;
      _contrast = (data['contrast'] as num?)?.toDouble() ?? 0.0;
      _temperature = (data['temperature'] as num?)?.toDouble() ?? 0.0;
      _saturation = (data['saturation'] as num?)?.toDouble() ?? 0.0;
      _fade = (data['fade'] as num?)?.toDouble() ?? 0.0;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _tempBrightness = _brightness;
      _tempExposure = _exposure;
      _tempContrast = _contrast;
      _tempTemperature = _temperature;
      _tempSaturation = _saturation;
      _tempFade = _fade;
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _brightness = _tempBrightness;
      _exposure = _tempExposure;
      _contrast = _tempContrast;
      _temperature = _tempTemperature;
      _saturation = _tempSaturation;
      _fade = _tempFade;
      _isEditing = false;
    });
  }

  Future<void> _saveEditing() async {
    final id = widget.photos[_currentIndex]['id'] as int;
    await DatabaseService().updatePhotoAdjustments(
      id,
      brightness: _brightness,
      exposure: _exposure,
      contrast: _contrast,
      temperature: _temperature,
      saturation: _saturation,
      fade: _fade,
    );
    
    // Update local list to persist changes when swiping back
    widget.photos[_currentIndex]['brightness'] = _brightness;
    widget.photos[_currentIndex]['exposure'] = _exposure;
    widget.photos[_currentIndex]['contrast'] = _contrast;
    widget.photos[_currentIndex]['temperature'] = _temperature;
    widget.photos[_currentIndex]['saturation'] = _saturation;
    widget.photos[_currentIndex]['fade'] = _fade;

    setState(() {
      _isEditing = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu các tùy chỉnh màu sắc')),
      );
    }
  }

  Future<void> _downloadPhoto() async {
    final path = widget.photos[_currentIndex]['path'] as String;
    try {
      await Gal.putImage(path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu ảnh vào thiết bị')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải xuống: $e')),
        );
      }
    }
  }

  Future<void> _deletePhoto() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Xóa ảnh', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bạn có chắc chắn muốn xóa ảnh này không?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final id = widget.photos[_currentIndex]['id'] as int;
      final path = widget.photos[_currentIndex]['path'] as String;

      await DatabaseService().deletePhoto(id);
      try {
        final file = File(path);
        if (file.existsSync()) await file.delete();
      } catch (e) {
        debugPrint('File deletion error: $e');
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${_currentIndex + 1} / ${widget.photos.length}'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Tải về máy',
            onPressed: _isEditing ? null : _downloadPhoto,
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded), // Replaced share with edit (tune) icon
            tooltip: 'Chỉnh sửa',
            onPressed: _isEditing ? null : _startEditing,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            tooltip: 'Xóa ảnh',
            onPressed: _isEditing ? null : _deletePhoto,
          ),
        ],
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (_isEditing) {
            _cancelEditing();
          } else {
            Navigator.of(context).pop(true);
          }
        },
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: _isEditing ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                itemCount: widget.photos.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                    _loadPhotoData(index);
                  });
                },
                itemBuilder: (context, index) {
                  final photo = widget.photos[index];
                  final file = File(photo['path'] as String);
                  final hasImage = file.existsSync();
                  
                  if (!hasImage) {
                    return const Center(child: Icon(Icons.broken_image, color: Colors.white38, size: 64));
                  }

                  // Use local state values for the CURRENT image being edited
                  // and stored values for others
                  final double brightness = (index == _currentIndex) ? _brightness : ((photo['brightness'] as num?)?.toDouble() ?? 0.0);
                  final double exposure = (index == _currentIndex) ? _exposure : ((photo['exposure'] as num?)?.toDouble() ?? 0.0);
                  final double contrast = (index == _currentIndex) ? _contrast : ((photo['contrast'] as num?)?.toDouble() ?? 0.0);
                  final double temperature = (index == _currentIndex) ? _temperature : ((photo['temperature'] as num?)?.toDouble() ?? 0.0);
                  final double saturation = (index == _currentIndex) ? _saturation : ((photo['saturation'] as num?)?.toDouble() ?? 0.0);
                  final double fade = (index == _currentIndex) ? _fade : ((photo['fade'] as num?)?.toDouble() ?? 0.0);

                  final matrix = _calculateCombinedMatrix(
                    brightness: brightness,
                    exposure: exposure,
                    contrast: contrast,
                    temperature: temperature,
                    saturation: saturation,
                    fade: fade,
                  );

                  return Column(
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ColorFiltered(
                            colorFilter: ColorFilter.matrix(matrix),
                            child: Image.file(
                              file,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        ),
                      ),
                      if (!_isEditing)
                        _buildInfoPanel(
                          instruction: photo['instruction'] as String? ?? '',
                          tags: (photo['tags'] as String? ?? '').split(',').where((t) => t.isNotEmpty).toList(),
                        ),
                    ],
                  );
                },
              ),
            ),
            
            // Edit Panel
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                );
              },
              child: _isEditing ? _buildEditPanel() : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.grey[950],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white10, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ĐIỀU CHỈNH ẢNH',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _brightness = 0.0;
                    _exposure = 0.0;
                    _contrast = 0.0;
                    _temperature = 0.0;
                    _saturation = 0.0;
                    _fade = 0.0;
                  });
                },
                child: const Text(
                  'Đặt lại',
                  style: TextStyle(color: Color(0xFF00FFCC), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildSlider(label: 'Độ sáng', value: _brightness, onChanged: (val) => setState(() => _brightness = val), min: -1.0, max: 1.0),
                _buildSlider(label: 'Phơi sáng', value: _exposure, onChanged: (val) => setState(() => _exposure = val), min: -1.0, max: 1.0),
                _buildSlider(label: 'Tương phản', value: _contrast, onChanged: (val) => setState(() => _contrast = val), min: -1.0, max: 1.0),
                _buildSlider(label: 'Nhiệt màu', value: _temperature, onChanged: (val) => setState(() => _temperature = val), min: -1.0, max: 1.0),
                _buildSlider(label: 'Bão hòa', value: _saturation, onChanged: (val) => setState(() => _saturation = val), min: -1.0, max: 1.0),
                _buildSlider(label: 'Fade', value: _fade, onChanged: (val) => setState(() => _fade = val), min: 0.0, max: 1.0),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _cancelEditing,
                  child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FFCC),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _saveEditing,
                  child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({required String label, required double value, required ValueChanged<double> onChanged, required double min, required double max}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(
                value >= 0 ? '+${(value * 100).toStringAsFixed(0)}%' : '${(value * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Color(0xFF00FFCC), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF00FFCC),
              inactiveTrackColor: Colors.white10,
              thumbColor: const Color(0xFF00FFCC),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(value: value, min: min, max: max, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel({required String instruction, required List<String> tags}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Gợi ý AI', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2)),
          const SizedBox(height: 6),
          Text(instruction, style: const TextStyle(color: Colors.white, fontSize: 14)),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Thẻ ảnh', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                child: Text(tag, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              )).toList(),
            ),
          ],
          const SizedBox(height: 12),
        ],
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
    List<double> m = [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];

    double expScale = exposure >= 0 ? (1.0 + exposure) : (1.0 + exposure * 0.5);
    m[0] *= expScale; m[6] *= expScale; m[12] *= expScale;

    double brOffset = brightness * 80;
    m[4] += brOffset; m[9] += brOffset; m[14] += brOffset;

    if (contrast != 0) {
      double cFactor = contrast >= 0 ? (1.0 + contrast * 0.8) : (1.0 + contrast * 0.5);
      double offset = 128.0 * (1.0 - cFactor);
      m[0] *= cFactor; m[4] = m[4] * cFactor + offset;
      m[6] *= cFactor; m[9] = m[9] * cFactor + offset;
      m[12] *= cFactor; m[14] = m[14] * cFactor + offset;
    }

    if (temperature != 0) {
      double tempShift = temperature * 30;
      m[4] += tempShift; m[9] += tempShift * 0.5; m[14] -= tempShift;
    }

    if (saturation != 0) {
      double sMult = saturation >= 0 ? (1.0 + saturation) : (1.0 + saturation * 0.8);
      double invS = 1.0 - sMult;
      double r = 0.2126 * invS; double g = 0.7152 * invS; double b = 0.0722 * invS;
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

    if (fade > 0) {
      double fadeFactor = 1.0 - fade * 0.25;
      double fadeOffset = fade * 35;
      m[0] *= fadeFactor; m[4] = m[4] * fadeFactor + fadeOffset;
      m[6] *= fadeFactor; m[9] = m[9] * fadeFactor + fadeOffset;
      m[12] *= fadeFactor; m[14] = m[14] * fadeFactor + fadeOffset;
    }
    return m;
  }
}
