import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project/providers/auth_provider.dart';
import 'package:project/providers/settings_provider.dart';
import 'package:project/ui/user_info_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _apiKeyController;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    final settingsLocal = ref.read(settingsProvider);
    _apiKeyController = TextEditingController(text: settingsLocal.openAIApiKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Cài đặt"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildSectionHeader("Cấu hình AI"),
          _buildSwitchTile(
            "Tự động Zoom",
            "Tự động phóng to khi bố cục chuẩn",
            settings.autoZoom,
            (val) => ref.read(settingsProvider.notifier).setAutoZoom(val),
          ),
          _buildSwitchTile(
            "Lưới Rule of Thirds",
            "Hiển thị lưới căn chỉnh 1/3",
            settings.showGrid,
            (val) => ref.read(settingsProvider.notifier).setShowGrid(val),
          ),
          _buildSwitchTile(
            "Sử dụng OpenAI Vision",
            "Đánh giá bố cục ảnh cuối bằng GPT-4o-mini",
            settings.useOpenAIVision,
            (val) => ref.read(settingsProvider.notifier).setUseOpenAIVision(val),
          ),

          if (settings.useOpenAIVision) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "OPENAI API KEY",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureApiKey,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    cursorColor: const Color(0xFF00FFCC),
                    decoration: InputDecoration(
                      hintText: "sk-proj-...",
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white10,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white54,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureApiKey = !_obscureApiKey;
                          });
                        },
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF00FFCC), width: 1.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white12, width: 1.0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).setOpenAIApiKey(val.trim());
                    },
                  ),
                ],
              ),
            ),
          ],
          
          _buildSectionHeader("Tài khoản"),
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
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Đăng xuất", style: TextStyle(color: Colors.redAccent)),
            onTap: () => ref.read(authStateProvider.notifier).logout(),
          ),
          
          _buildSectionHeader("Thông tin"),
          const ListTile(
            title: Text("Phiên bản", style: TextStyle(color: Colors.white)),
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

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      activeThumbColor: const Color(0xFF00FFCC),
      activeColor: const Color.fromARGB(255, 0, 150, 120),
    );
  }
}
