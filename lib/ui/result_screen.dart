import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:project/models/coach_result.dart';
import 'package:project/services/database_service.dart';
import 'package:share_plus/share_plus.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;
  final CoachResult result;

  const ResultScreen({
    super.key,
    required this.imagePath,
    required this.result,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _savePhoto();
  }

  Future<void> _savePhoto() async {
    try {
      await DatabaseService().savePhoto(
        path: widget.imagePath,
        result: widget.result,
        tags: [],
      );
      if (mounted) {
        setState(() {
          _isSaved = true;
        });
      }
    } catch (e) {
      debugPrint('Save error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Ảnh đã chụp'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.shareXFiles([XFile(widget.imagePath)], text: 'Check out my Kado Mac shot!');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(File(widget.imagePath)),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          if (_isSaved)
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF00FFCC), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Đã lưu vào bộ sưu tập',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ).animate().fadeIn().slideY(begin: 0.2, end: 0),
            ),
        ],
      ),
    );
  }
}
