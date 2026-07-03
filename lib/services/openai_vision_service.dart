import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:project/models/coach_result.dart';

class OpenAIVisionService {
  static final OpenAIVisionService instance = OpenAIVisionService._();
  OpenAIVisionService._();

  Future<CoachResult> evaluateLayout(File imageFile, String apiKey) async {
    const String url = 'https://api.openai.com/v1/chat/completions';

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };

      final body = jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Bạn là một chuyên gia nhiếp ảnh nghệ thuật và chụp ảnh di động. Hãy đánh giá chi tiết bố cục, ánh sáng và góc chụp của bức ảnh được gửi kèm dưới góc độ kỹ thuật (ví dụ: Quy tắc 1/3, Sự cân bằng, Đường dẫn, Tiêu cự/Độ nét). Trả về kết quả dưới dạng JSON hợp lệ duy nhất, KHÔNG chứa ký tự markdown hay văn bản bổ sung nào ngoài JSON. Cấu trúc JSON bắt buộc như sau:\n'
                    '{\n'
                    '  "score": 85.0,\n'
                    '  "isBalanced": true,\n'
                    '  "instruction": "Lời khuyên ngắn gọn chi tiết bằng tiếng Việt để cải thiện góc chụp hoặc chỉnh sửa ảnh (ví dụ: \'Dịch chuyển góc máy sang trái một chút để chủ thể rơi đúng đường lưới 1/3, hạ thấp góc chụp lấy tiền cảnh\')",\n'
                    '  "metrics": {\n'
                    '    "Quy tắc 1/3": 85.0,\n'
                    '    "Sự cân bằng": 80.0,\n'
                    '    "Độ nét": 90.0,\n'
                    '    "Ánh sáng & Màu sắc": 88.0\n'
                    '  }\n'
                    '}'
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image',
                }
              }
            ]
          }
        ],
        'response_format': {'type': 'json_object'},
        'temperature': 0.7,
      });

      debugPrint('OpenAIVisionService: Sending request to OpenAI API...');
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      debugPrint('OpenAIVisionService: Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
        final content = responseData['choices']?[0]?['message']?['content'] as String?;
        if (content != null) {
          debugPrint('OpenAIVisionService: Received content: $content');
          final parsedJson = jsonDecode(content) as Map<String, dynamic>;

          final double responseScore = ((parsedJson['score'] ?? 0.0) as num).toDouble();
          final bool responseIsBalanced = (parsedJson['isBalanced'] ?? false) as bool;
          final String responseInstruction = (parsedJson['instruction'] ?? 'Bố cục đẹp') as String;
          final Map<String, dynamic> rawMetrics = parsedJson['metrics'] ?? {};
          final Map<String, double> responseMetrics = {};
          rawMetrics.forEach((key, val) {
            responseMetrics[key] = (val as num).toDouble();
          });

          return CoachResult(
            score: responseScore,
            isBalanced: responseIsBalanced,
            instruction: responseInstruction,
            metrics: responseMetrics,
            imageSize: Size.zero, // Filled post-load if needed
          );
        }
      } else {
        debugPrint('OpenAIVisionService: Request failed: ${response.body}');
        return CoachResult(
          instruction: 'OpenAI API request failed: Status ${response.statusCode}',
          score: 50.0,
        );
      }
    } catch (e) {
      debugPrint('OpenAIVisionService: Exception occurred: $e');
      return CoachResult(
        instruction: 'Lỗi kết nối OpenAI hoặc xử lý ảnh: $e',
        score: 40.0,
      );
    }

    return CoachResult(
      instruction: 'Không thể đánh giá bố cục bằng OpenAI Vision',
      score: 30.0,
    );
  }
}
