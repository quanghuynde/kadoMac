import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project/providers/auth_provider.dart';

import 'package:project/ui/user_info_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Cài đặt"),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        children: [
          _buildSectionHeader("Cấu hình AI"),
          _buildSwitchTile(
            context,
            "Tự động Zoom",
            "Tự động phóng to khi bố cục chuẩn",
            true,
          ),
          _buildSwitchTile(
            context,
            "Lưới Rule of Thirds",
            "Hiển thị lưới căn chỉnh 1/3",
            true,
          ),
          
          _buildSectionHeader("Tài khoản"),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.white70),
            title: const Text("Thông tin cá nhân"),
            trailing: const Icon(Icons.chevron_right, color: Colors.white24),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserInfoScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Đăng xuất", style: TextStyle(color: Colors.redAccent)),
            onTap: () => ref.read(authStateProvider.notifier).logout(),
          ),
          
          _buildSectionHeader("Thông tin"),
          const ListTile(
            title: Text("Phiên bản"),
            trailing: Text("1.0.0 (Doka Style)", style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF00FFCC),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(BuildContext context, String title, String subtitle, bool value) {
    return SwitchListTile(
      value: value,
      onChanged: (val) {},
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      activeColor: const Color(0xFF00FFCC),
    );
  }
}
