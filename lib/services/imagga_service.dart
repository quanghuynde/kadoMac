import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImaggaService {
  final String apiKey = 'acc_fc5b8cf9cdff677';
  final String apiSecret = '7428fb764f4bfc315b45a8e53324e1f8';
  final String baseUrl = 'https://api.imagga.com/v2';

  String get _authHeader {
    final bytes = utf8.encode('$apiKey:$apiSecret');
    final base64Auth = base64.encode(bytes);
    return 'Basic $base64Auth';
  }

  Future<Map<String, dynamic>> analyzeImage(String imagePath) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/tags'));
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      request.headers['Authorization'] = _authHeader;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to analyze image: ${response.body}');
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Imagga also has a categorization endpoint which can be useful for scene detection
  Future<Map<String, dynamic>> categorizeImage(String imagePath) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/categories/personal_photos'));
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      request.headers['Authorization'] = _authHeader;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': response.body};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
