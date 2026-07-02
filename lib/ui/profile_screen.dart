import 'package:flutter/material.dart';
import 'package:project/services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _db = DatabaseService();
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
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
        title: const Text("Hồ sơ năng lực"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem("Tổng ảnh", _stats?['total']?.toString() ?? "0"),
                  _statItem("Điểm TB", "${(_stats?['avgScore'] ?? 0.0).toStringAsFixed(1)}%"),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            const Text(
              "Lịch sử chụp ảnh",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            
            // History List
            if (_history.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: Text("Chưa có ảnh nào được lưu", style: TextStyle(color: Colors.white38)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final item = _history[index];
                  return ListTile(
                    leading: const Icon(Icons.photo, color: Color(0xFF00FFCC)),
                    title: Text(
                      "Ảnh ngày ${DateTime.parse(item['timestamp']).day}/${DateTime.parse(item['timestamp']).month}",
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      "Điểm: ${item['overall_score'].toStringAsFixed(0)}% - ${item['tags']}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white24),
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
        Text(value, style: const TextStyle(color: Color(0xFF00FFCC), fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
