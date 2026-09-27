import 'dart:convert';
import 'package:http/http.dart' as http;

// Data satu kota (hasil pencarian atau pilihan awal)
class City {
  final String name;
  final String region; // provinsi / negara bagian
  final String country;
  final double latitude;
  final double longitude;

  const City({
    required this.name,
    required this.region,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  // Teks kedua, contoh: "Riau, Indonesia"
  String get subtitle {
    final parts = <String>[];
    if (region.isNotEmpty) parts.add(region);
    if (country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }

  // Teks lengkap, contoh: "Batam, Riau, Indonesia"
  String get label {
    final sub = subtitle;
    return sub.isEmpty ? name : '$name, $sub';
  }
}

// Data cuaca untuk satu hari
class DayWeather {
  final String emoji;
  final String description;
  final double maxTemp;
  final double minTemp;

  const DayWeather({
    required this.emoji,
    required this.description,
    required this.maxTemp,
    required this.minTemp,
  });
}

class WeatherService {
  // Kota awal saat aplikasi pertama dibuka
  static const City defaultCity = City(
    name: 'Batam',
    region: 'Riau',
    country: 'Indonesia',
    latitude: 1.0456,
    longitude: 104.0305,
  );

  // Mengubah tanggal menjadi teks "2026-09-21"
  // Dipakai sebagai kunci untuk mencari cuaca per tanggal.
  static String keyOf(DateTime d) {
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day';
  }

  // Mencari kota berdasarkan nama (API geocoding Open-Meteo)
  static Future<List<City>> searchCity(String query) async {
    final url = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search'
      '?name=${Uri.encodeQueryComponent(query)}'
      '&count=8'
      '&language=en'
      '&format=json',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('City search failed');
    }

    final data = jsonDecode(response.body);

    // Kalau kota tidak ditemukan, kunci 'results' tidak ada
    final results = data['results'] as List?;
    if (results == null) return [];

    return results.map<City>((r) {
      return City(
        name: (r['name'] ?? '') as String,
        region: (r['admin1'] ?? '') as String,
        country: (r['country'] ?? '') as String,
        latitude: (r['latitude'] as num).toDouble(),
        longitude: (r['longitude'] as num).toDouble(),
      );
    }).toList();
  }

  // Mengambil cuaca 7 hari ke belakang dan 16 hari ke depan untuk kota ini.
  // Hasilnya berupa Map: kunci = tanggal, isi = cuaca hari itu.
  static Future<Map<String, DayWeather>> fetchWeather(City city) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=${city.latitude}'
      '&longitude=${city.longitude}'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min'
      '&timezone=auto'
      '&past_days=7'
      '&forecast_days=16',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Weather request failed');
    }

    final data = jsonDecode(response.body);
    final daily = data['daily'];

    final dates = daily['time'] as List;
    final codes = daily['weather_code'] as List;
    final maxTemps = daily['temperature_2m_max'] as List;
    final minTemps = daily['temperature_2m_min'] as List;

    final result = <String, DayWeather>{};

    for (int i = 0; i < dates.length; i++) {
      // Lewati hari yang datanya kosong
      if (codes[i] == null || maxTemps[i] == null || minTemps[i] == null) {
        continue;
      }

      final info = _describe((codes[i] as num).toInt());
      result[dates[i] as String] = DayWeather(
        emoji: info[0],
        description: info[1],
        maxTemp: (maxTemps[i] as num).toDouble(),
        minTemp: (minTemps[i] as num).toDouble(),
      );
    }

    return result;
  }

  // Mengubah kode cuaca (standar WMO) menjadi emoji + keterangan
  static List<String> _describe(int code) {
    if (code == 0) return ['☀️', 'Clear'];
    if (code == 1) return ['🌤️', 'Mostly clear'];
    if (code == 2) return ['⛅', 'Partly cloudy'];
    if (code == 3) return ['☁️', 'Cloudy'];
    if (code == 45 || code == 48) return ['🌫️', 'Fog'];
    if (code >= 51 && code <= 57) return ['🌦️', 'Drizzle'];
    if (code >= 61 && code <= 67) return ['🌧️', 'Rain'];
    if (code >= 71 && code <= 77) return ['❄️', 'Snow'];
    if (code >= 80 && code <= 82) return ['🌦️', 'Rain showers'];
    if (code == 85 || code == 86) return ['❄️', 'Snow showers'];
    if (code >= 95 && code <= 99) return ['⛈️', 'Thunderstorm'];
    return ['🌡️', 'Unknown'];
  }
}