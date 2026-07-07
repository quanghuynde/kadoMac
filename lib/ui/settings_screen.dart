import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project/providers/auth_provider.dart';
import 'package:project/providers/settings_provider.dart';
import 'package:project/ui/user_info_screen.dart';
import 'package:project/utils/animation_config.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Cài đặt").animate().fadeIn(
          duration: AppAnimations.fast,
          curve: AppAnimations.easeOut,
        ).slideX(
          begin: -0.2,
          end: 0,
          duration: AppAnimations.normal,
          curve: AppAnimations.easeOutCubic,
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Section: AI Configuration - staggered entrance
          _buildSectionHeader("Cấu hình AI").animate().fadeIn(
            duration: AppAnimations.normal,
            delay: AppAnimations.staggerFast,
            curve: AppAnimations.easeOut,
          ).slideX(
            begin: -0.15,
            end: 0,
            duration: AppAnimations.normal,
            delay: AppAnimations.staggerFast,
            curve: AppAnimations.easeOutCubic,
          ),
          _buildSwitchTile(
            "Tự động Zoom",
            "Tự động phóng to khi bố cục chuẩn",
            settings.autoZoom,
            (val) => ref.read(settingsProvider.notifier).setAutoZoom(val),
          ).animate().fadeIn(
            duration: AppAnimations.normal,
            delay: AppAnimations.staggerNormal,
            curve: AppAnimations.easeOut,
          ).slideX(
            begin: -0.15,
            end: 0,
            duration: AppAnimations.normal,
            delay: AppAnimations.staggerNormal,
            curve: AppAnimations.easeOutCubic,
          ),
          _buildSwitchTile(
            "Lưới Rule of Thirds",
            "Hiển thị lưới căn chỉnh 1/3",
            settings.showGrid,
            (val) => ref.read(settingsProvider.notifier).setShowGrid(val),
          ).animate().fadeIn(
            duration: AppAnimations.normal,
            delay: AppAnimations.staggerSlow,
            curve: AppAnimations.easeOut,
          ).slideX(
            begin: -0.15,
            end: 0,
            duration: AppAnimations.normal,
            delay: AppAnimations.staggerSlow,
            curve: AppAnimations.easeOutCubic,
          ),

          // Section: Account
          _buildSectionHeader("Tài khoản").animate().fadeIn(
            duration: AppAnimations.normal,
            delay: const Duration(milliseconds: 350),
            curve: AppAnimations.easeOut,
          ).slideX(
            begin: -0.15,
            end: 0,
            duration: AppAnimations.normal,
            delay: const Duration(milliseconds: 350),
            curve: AppAnimations.easeOutCubic,
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.white70),
            title: const Text("Thông tin cá nhân", style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white24),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserInfoScreen()),
              );
            },
          ).animate().fadeIn(
            duration: AppAnimations.normal,
            delay: const Duration(milliseconds: 400),
            curve: AppAnimations.easeOut,
          ).slideX(
            begin: -0.15,
            end: 0,
            duration: AppAnimations.normal,
            delay: const Duration(milliseconds: 400),
            curve: AppAnimations.easeOutCubic,
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Đăng xuất", style: TextStyle(color: Colors.redAccent)),
            onTap: () => ref.read(authStateProvider.notifier).logout(),
          ).animate().fadeIn(
            duration: AppAnimations.normal,
            delay: const Duration(milliseconds: 450),
            curve: AppAnimations.easeOut,
          ).slideX(
            begin: -0.15,
            end: 0,
            duration: AppAnimations.normal,
            delay: const Duration(milliseconds: 450),
            curve: AppAnimations.easeOutCubic,
          ),

          // Section: Info
          _buildSectionHeader("Thông tin").animate().fadeIn(
            duration: AppAnimations.normal,
            delay: const Duration(milliseconds: 500),
            curve: AppAnimations.easeOut,
          ).slideX(
            begin: -0.15,
            end: 0,
            duration: AppAnimations.normal,
            delay: const Duration(milliseconds: 500),
            curve: AppAnimations.easeOutCubic,
          ),
          const ListTile(
            title: Text("Phiên bản", style: TextStyle(color: Colors.white)),
            trailing: Text("1.0.0", style: TextStyle(color: Colors.white38)),
          ).animate().fadeIn(
            duration: AppAnimations.normal,
            delay: const Duration(milliseconds: 550),
            curve: AppAnimations.easeOut,
          ).slideX(
            begin: -0.15,
            end: 0,
            duration: AppAnimations.normal,
            delay: const Duration(milliseconds: 550),
            curve: AppAnimations.easeOutCubic,
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

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      activeThumbColor: const Color(0xFF00FFCC),
      activeTrackColor: const Color.fromARGB(255, 0, 150, 120),
    );
  }
}