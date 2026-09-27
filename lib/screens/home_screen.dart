import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../widgets/city_search_sheet.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // Kota yang sedang dipilih (awalnya kota bawaan)
  City _city = WeatherService.defaultCity;

  // Data cuaca: kunci = tanggal ("2026-09-21"), isi = cuaca hari itu
  Map<String, DayWeather> _weather = {};
  bool _weatherLoading = true;
  bool _weatherFailed = false;

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  // initState dijalankan sekali saat halaman pertama kali dibuka
  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  // Mengunduh cuaca untuk kota yang sedang dipilih
  Future<void> _loadWeather() async {
    final city = _city;
    try {
      final data = await WeatherService.fetchWeather(city);
      // Abaikan hasil kalau user sudah keburu ganti kota lagi
      if (!mounted || city != _city) return;
      setState(() {
        _weather = data;
        _weatherLoading = false;
      });
    } catch (e) {
      if (!mounted || city != _city) return;
      setState(() {
        _weatherLoading = false;
        _weatherFailed = true;
      });
    }
  }

  // Membuka panel pencarian kota, lalu memuat cuaca kota yang dipilih
  Future<void> _pickCity() async {
    final City? picked = await showModalBottomSheet<City>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const CitySearchSheet(),
    );

    // null = user menutup panel tanpa memilih
    if (picked == null || !mounted) return;

    setState(() {
      _city = picked;
      _weather = {};
      _weatherLoading = true;
      _weatherFailed = false;
    });
    _loadWeather();
  }

  // Mengubah DateTime menjadi teks, contoh: "21 September 2026"
  String _formatDate(DateTime date) {
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }

  // Teks cuaca untuk tanggal yang dipilih
  String _weatherText() {
    if (_weatherLoading) return 'Loading weather...';
    if (_weatherFailed) return 'Weather unavailable (check your internet)';

    final w = _weather[WeatherService.keyOf(_selectedDay)];
    if (w == null) return 'No weather data for this date';

    return '${w.emoji} ${w.description}, '
        '${w.maxTemp.round()}° / ${w.minTemp.round()}°C';
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 12),

            // Baris kota + tombol ganti kota
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 4),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppTheme.navy),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _city.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.navy,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _pickCity,
                      child: const Text(
                        'Change',
                        style: TextStyle(color: AppTheme.navy),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Kalender
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2035, 12, 31),
                  focusedDay: _focusedDay,
                  rowHeight: 60,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  // Dipanggil saat user menggeser ke bulan lain
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy,
                    ),
                  ),
                  calendarStyle: const CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: AppTheme.navy,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: AppTheme.lightBlue,
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(color: AppTheme.navy),
                  ),
                  // Menaruh emoji cuaca di bawah setiap tanggal
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      final w = _weather[WeatherService.keyOf(day)];
                      if (w == null) return null;
                      return Positioned(
                        bottom: 0,
                        child: Text(
                          w.emoji,
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tanggal terpilih di bawah kalender
            Text(
              'Selected: ${_formatDate(_selectedDay)}',
              style: const TextStyle(fontSize: 16, color: AppTheme.navy),
            ),
            const SizedBox(height: 12),

            // Card info
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event, color: AppTheme.navy),
                        const SizedBox(width: 8),
                        Text('Selected Date: ${_formatDate(_selectedDay)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.wb_sunny_outlined,
                            color: AppTheme.navy),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Weather: ${_weatherText()}')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.list_alt, color: AppTheme.navy),
                        SizedBox(width: 8),
                        Text('Number of events: 0'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add event feature coming soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}