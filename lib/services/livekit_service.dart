import 'dart:convert';
import 'package:http/http.dart' as http;

class LiveKitService {
  // 🔥 YOUR COMPUTER IP HERE!
  static const String tokenServerUrl = 'http://192.168.1.2:8000';

  static Future<Map<String, String>> getToken({
    required String roomName,
    required String participantName,
  }) async {
    try {
      print('🔑 Requesting token from $tokenServerUrl/get-token');

      final response = await http.post(
        Uri.parse('$tokenServerUrl/get-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'room_name': roomName,
          'participant_name': participantName,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Token received');
        return {
          'token': data['token'],
          'url': data['url'],
        };
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Token error: $e');
      rethrow;
    }
  }

  static Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$tokenServerUrl/health'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Health check failed: $e');
      return false;
    }
  }
}
