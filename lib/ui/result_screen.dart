import 'dart:io';
import 'package:flutter/material.dart';
import 'package:project/models/coach_result.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';

class ResultScreen extends StatelessWidget {
  final String imagePath;
  final CoachResult result;

  const ResultScreen({
    super.key,
    required this.imagePath,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Kết quả phân tích'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: FileImage(File(imagePath)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ĐIỂM TỔNG QUAN',
                      style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2),
                    ),
                    Text(
                      '${result.score.toStringAsFixed(0)}%',
                      style: const TextStyle(color: Color(0xFF00FFCC), fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 32),
                ...result.metrics.entries.map((e) => _buildMetric(e.key, e.value)),
                const SizedBox(height: 24),
                const Text(
                  'GỢI Ý TỪ AI:',
                  style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  result.instruction,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.download,
                        label: 'Lưu lại',
                        onTap: () => _downloadImage(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.share,
                        label: 'Chia sẻ',
                        isSecondary: true,
                        onTap: () => _shareImage(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / 100,
                backgroundColor: Colors.white10,
                color: const Color(0xFF00FFCC),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('${value.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _downloadImage(BuildContext context) async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) await Gal.requestAccess();
      await Gal.putImage(imagePath);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu vào bộ sưu tập!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi lưu: $e')));
      }
    }
  }

  Future<void> _shareImage() async {
    await Share.shareXFiles([XFile(imagePath)], text: 'Xem ảnh tôi chụp bằng AI Camera Coach!');
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSecondary;

  const _ActionButton({required this.icon, required this.label, required this.onTap, this.isSecondary = false});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.black),
      label: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSecondary ? Colors.white70 : const Color(0xFF00FFCC),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
