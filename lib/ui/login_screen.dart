import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project/providers/auth_provider.dart';
import 'package:project/ui/register_screen.dart';
import 'package:project/utils/animation_config.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo with bounce + rotate
            const Icon(Icons.camera_enhance, size: 80, color: Colors.blue)
              .animate()
              .scaleXY(begin: 0, end: 1, duration: AppAnimations.slow, curve: AppAnimations.elasticOut)
              .rotate(begin: -0.3, end: 0, duration: AppAnimations.normal, curve: AppAnimations.easeOutCubic),

            const SizedBox(height: 24),

            // Title
            const Text(
              'AI Camera Coach',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ).animate().fadeIn(
              duration: AppAnimations.normal,
              delay: AppAnimations.staggerNormal,
              curve: AppAnimations.easeOut,
            ).slideY(
              begin: 0.3,
              end: 0,
              duration: AppAnimations.normal,
              delay: AppAnimations.staggerNormal,
              curve: AppAnimations.easeOutCubic,
            ),

            const SizedBox(height: 48),

            // Email field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email hoặc số điện thoại',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ).animate().fadeIn(
              duration: AppAnimations.normal,
              delay: AppAnimations.staggerSlow,
              curve: AppAnimations.easeOut,
            ).slideX(
              begin: -0.3,
              end: 0,
              duration: AppAnimations.normal,
              delay: AppAnimations.staggerSlow,
              curve: AppAnimations.easeOutCubic,
            ),

            const SizedBox(height: 16),

            // Password field
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ).animate().fadeIn(
              duration: AppAnimations.normal,
              delay: const Duration(milliseconds: 350),
              curve: AppAnimations.easeOut,
            ).slideX(
              begin: -0.3,
              end: 0,
              duration: AppAnimations.normal,
              delay: const Duration(milliseconds: 350),
              curve: AppAnimations.easeOutCubic,
            ),

            const SizedBox(height: 24),

            // Login button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator() 
                : const Text('Đăng nhập', style: TextStyle(fontSize: 18)),
            ).animate().fadeIn(
              duration: AppAnimations.normal,
              delay: const Duration(milliseconds: 450),
              curve: AppAnimations.easeOut,
            ).scaleXY(
              begin: 0.9,
              end: 1,
              duration: AppAnimations.normal,
              delay: const Duration(milliseconds: 450),
              curve: AppAnimations.easeOutCubic,
            ),

            // Register link
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
              },
              child: const Text("Chưa có tài khoản? Đăng ký ngay"),
            ).animate().fadeIn(
              duration: AppAnimations.normal,
              delay: AppAnimations.slow,
              curve: AppAnimations.easeOut,
            ).slideY(
              begin: 0.2,
              end: 0,
              duration: AppAnimations.normal,
              delay: AppAnimations.slow,
              curve: AppAnimations.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    final success = await ref.read(authStateProvider.notifier).login(
      _emailController.text,
      _passwordController.text,
    );
    setState(() => _isLoading = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials')),
      );
    }
  }
}