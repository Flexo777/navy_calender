
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  // Sesuaikan dengan URL backend kamu.
  static const String baseUrl = 'https://dummyjson.com';

  static Future<Map<String, String>?> login(
    String username,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'username': username,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        if (decoded is! Map<String, dynamic>) {
          return null;
        }

        // Mendukung respons token langsung atau di dalam "data".
        final dynamic payload = decoded['data'] is Map
            ? decoded['data']
            : decoded;

        if (payload is! Map) {
          return null;
        }

        final accessToken = payload['accessToken'];
        final refreshToken = payload['refreshToken'];

        if (accessToken is String &&
            accessToken.isNotEmpty &&
            refreshToken is String &&
            refreshToken.isNotEmpty) {
          return {
            'accessToken': accessToken,
            'refreshToken': refreshToken,
          };
        }

        return null;
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
