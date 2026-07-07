import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:project/services/database_service.dart';
import 'package:project/utils/animation_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    final stats = await _db.getStats();
    final history = await _db.getPhotoHistory();
    if (mounted) {
      setState(() {
        _stats = stats;
        _history = history;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Hồ sơ năng lực")
            .animate()
            .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.easeOut)
            .slideX(
              begin: -0.2,
              end: 0,
              duration: AppAnimations.normal,
              curve: AppAnimations.easeOutCubic,
            ),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Card
            Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _statItem(
                        "Tổng số ảnh đã chụp",
                        _stats?['total']?.toString() ?? "0",
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(
                  duration: AppAnimations.normal,
                  delay: AppAnimations.staggerFast,
                  curve: AppAnimations.easeOut,
                )
                .scaleXY(
                  begin: 0.92,
                  end: 1,
                  duration: AppAnimations.normal,
                  delay: AppAnimations.staggerFast,
                  curve: AppAnimations.elasticOut,
                ),

            const SizedBox(height: 30),

            // History title
            const Text(
                  "Lịch sử chụp ảnh",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )
                .animate()
                .fadeIn(
                  duration: AppAnimations.normal,
                  delay: AppAnimations.staggerNormal,
                  curve: AppAnimations.easeOut,
                )
                .slideX(
                  begin: -0.2,
                  end: 0,
                  duration: AppAnimations.normal,
                  delay: AppAnimations.staggerNormal,
                  curve: AppAnimations.easeOutCubic,
                ),

            const SizedBox(height: 15),

            // History List
            if (_history.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: Text(
                    "Chưa có ảnh nào được lưu",
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
              ).animate().fadeIn(
                duration: AppAnimations.normal,
                delay: AppAnimations.staggerSlow,
                curve: AppAnimations.easeOut,
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final item = _history[index];
                  return ListTile(
                        leading: const Icon(
                          Icons.photo,
                          color: Color(0xFF00FFCC),
                        ),
                        title: Text(
                          "Ảnh ngày ${DateTime.parse(item['timestamp']).day}/${DateTime.parse(item['timestamp']).month}",
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          "Tags: ${item['tags']}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white54),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.white24,
                        ),
                      )
                      .animate()
                      .fadeIn(
                        duration: AppAnimations.normal,
                        delay:
                            AppAnimations.staggerSlow +
                            (AppAnimations.staggerNormal * index),
                        curve: AppAnimations.easeOut,
                      )
                      .slideX(
                        begin: -0.2,
                        end: 0,
                        duration: AppAnimations.normal,
                        delay:
                            AppAnimations.staggerSlow +
                            (AppAnimations.staggerNormal * index),
                        curve: AppAnimations.easeOutCubic,
                      );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF00FFCC),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
