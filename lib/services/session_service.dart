
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class SessionService {
  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  // GANTI dengan URL backend kamu.
  // Contoh emulator Android: http://10.0.2.2:8000
  // Contoh HP fisik: http://IP-KOMPUTER:8000
  static const String baseUrl = 'http://10.0.2.2:8000';

  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  // Simpan access token dan refresh token
  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(
      key: _accessTokenKey,
      value: accessToken,
    );

    await _storage.write(
      key: _refreshTokenKey,
      value: refreshToken,
    );
  }

  // Ambil access token
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  // Ambil refresh token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // Hapus sesi login
  static Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  // Verifikasi sesi ke server, bukan hanya secara lokal
  static Future<bool> isSessionValid() async {
    try {
      final token = await getAccessToken();

      // Tidak ada token berarti belum login
      if (token == null || token.isEmpty) {
        return false;
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/auth/me'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      }

      if (response.statusCode == 401 ||
          response.statusCode == 403) {
        await clearSession();
      }

      return false;
    } catch (e) {
      // Jika server tidak dapat dijangkau,
      // jangan menganggap sesi sudah terverifikasi.
      return false;
    }
  }
}
