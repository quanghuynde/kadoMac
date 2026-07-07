import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project/providers/auth_provider.dart';
import 'package:project/utils/animation_config.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register').animate().fadeIn(
          duration: AppAnimations.fast,
          curve: AppAnimations.easeOut,
        ).slideX(
          begin: -0.2,
          end: 0,
          duration: AppAnimations.normal,
          curve: AppAnimations.easeOutCubic,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ).animate().fadeIn(
              duration: AppAnimations.normal,
              delay: AppAnimations.staggerNormal,
              curve: AppAnimations.easeOut,
            ).slideX(
              begin: -0.3,
              end: 0,
              duration: AppAnimations.normal,
              delay: AppAnimations.staggerNormal,
              curve: AppAnimations.easeOutCubic,
            ),

            const SizedBox(height: 16),

            // Password field
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
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

            const SizedBox(height: 24),

            // Create Account button
            ElevatedButton(
              onPressed: _handleRegister,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Create Account'),
            ).animate().fadeIn(
              duration: AppAnimations.normal,
              delay: const Duration(milliseconds: 350),
              curve: AppAnimations.easeOut,
            ).scaleXY(
              begin: 0.9,
              end: 1,
              duration: AppAnimations.normal,
              delay: const Duration(milliseconds: 350),
              curve: AppAnimations.elasticOut,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    await ref.read(authStateProvider.notifier).register(
      _emailController.text,
      _passwordController.text,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please login.')),
      );
      Navigator.pop(context);
    }
  }
}