import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://dummyjson.com';

  // Mengirim username & password ke server.
  // Mengembalikan token jika berhasil, atau null jika login salah.
  static Future<String?> login(String username, String password) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['accessToken'] ?? data['token']) as String?;
    }
    return null; // login gagal (username/password salah)
  }
}