import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project/providers/ai_coach_provider.dart';
import 'package:project/providers/sensor_provider.dart';
import 'package:project/ui/widgets/overlay_painter.dart';

class GuidanceOverlay extends ConsumerWidget {
  const GuidanceOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(aiCoachProvider);
    final horizonAngle = ref.watch(sensorProvider).value ?? 0.0;
    
    return Stack(
      children: [
        // Grid, Horizon, Ring, Dots
        CustomPaint(
          size: Size.infinite,
          painter: OverlayPainter(
            result: aiState.result,
            horizonAngle: horizonAngle,
            showGrid: aiState.isEnabled,
            status: aiState.status,
          ),
        ),
        
        // AI Bubble (Top Center - Style Doka)
        if (aiState.isEnabled)
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: _AIBubble(status: aiState.status, instruction: aiState.result.instruction),
            ),
          ),
          
        // Tag Overlay (Near subject)
        if (aiState.status == AICoachStatus.finished)
          const Positioned(
            bottom: 180,
            left: 0,
            right: 0,
            child: Center(child: _CapturePrompt()),
          ),
          
        // Tags list (Side)
        if (aiState.tags.isNotEmpty)
          Positioned(
            left: 20,
            top: 150,
            child: _TagCloud(tags: aiState.tags),
          ),
      ],
    );
  }
}

class _AIBubble extends StatelessWidget {
  final AICoachStatus status;
  final String instruction;

  const _AIBubble({required this.status, required this.instruction});

  @override
  Widget build(BuildContext context) {
    String title = "AI đang phân tích...";
    String subtitle = "Vui lòng giữ im máy, không di chuyển";
    
    if (status == AICoachStatus.guiding) {
      title = "Căn chỉnh bố cục";
      subtitle = "Hãy đưa chủ thể vào vòng tròn";
    } else if (status == AICoachStatus.finished) {
      title = "Bố cục đẹp";
      subtitle = "Sẵn sàng chụp ngay";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CapturePrompt extends StatelessWidget {
  const _CapturePrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF00FFCC), // Đổi sang xanh khi khớp
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF00FFCC).withValues(alpha: 0.4), blurRadius: 10),
        ],
      ),
      child: const Text(
        "ĐÃ KHÓA BỐ CỤC",
        style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _TagCloud extends StatelessWidget {
  final List<String> tags;
  const _TagCloud({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tags.map((tag) => Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            tag,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),
      )).toList(),
    );
  }
}
