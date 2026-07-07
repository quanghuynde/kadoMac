import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:project/utils/animation_config.dart';

class UserInfoScreen extends StatelessWidget {
  const UserInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Thông tin cá nhân").animate().fadeIn(
          duration: AppAnimations.fast,
          curve: AppAnimations.easeOut,
        ).slideX(
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
          children: [
            const SizedBox(height: 20),
            // Avatar
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF00FFCC),
              child: Icon(Icons.person, size: 60, color: Colors.black),
            ).animate().scaleXY(
              begin: 0,
              end: 1,
              duration: AppAnimations.slow,
              curve: AppAnimations.elasticOut,
            ).fadeIn(
              duration: AppAnimations.normal,
              curve: AppAnimations.easeOut,
            ),

            const SizedBox(height: 30),

            // Info tiles with staggered entrance
            _buildInfoTile("Họ và tên", "Người dùng AI").animate().fadeIn(
              duration: AppAnimations.normal,
              delay: AppAnimations.staggerNormal,
              curve: AppAnimations.easeOut,
            ).slideX(
              begin: -0.2,
              end: 0,
              duration: AppAnimations.normal,
              delay: AppAnimations.staggerNormal,
              curve: AppAnimations.easeOutCubic,
            ),

            _buildInfoTile("Email", "admin@gmail.com").animate().fadeIn(
              duration: AppAnimations.normal,
              delay: AppAnimations.staggerSlow,
              curve: AppAnimations.easeOut,
            ).slideX(
              begin: -0.2,
              end: 0,
              duration: AppAnimations.normal,
              delay: AppAnimations.staggerSlow,
              curve: AppAnimations.easeOutCubic,
            ),

            _buildInfoTile("Hạng thành viên", "Gold Member").animate().fadeIn(
              duration: AppAnimations.normal,
              delay: const Duration(milliseconds: 300),
              curve: AppAnimations.easeOut,
            ).slideX(
              begin: -0.2,
              end: 0,
              duration: AppAnimations.normal,
              delay: const Duration(milliseconds: 300),
              curve: AppAnimations.easeOutCubic,
            ),

            const SizedBox(height: 40),

            // Update button
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FFCC),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Cập nhật thông tin", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ).animate().fadeIn(
              duration: AppAnimations.normal,
              delay: const Duration(milliseconds: 400),
              curve: AppAnimations.easeOut,
            ).scaleXY(
              begin: 0.92,
              end: 1,
              duration: AppAnimations.normal,
              delay: const Duration(milliseconds: 400),
              curve: AppAnimations.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}