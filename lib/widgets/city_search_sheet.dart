import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';

// Panel yang muncul dari bawah untuk mencari dan memilih kota.
// Saat kota dipilih, panel menutup dan mengembalikan City ke halaman Home.
class CitySearchSheet extends StatefulWidget {
  const CitySearchSheet({super.key});

  @override
  State<CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends State<CitySearchSheet> {
  final TextEditingController _controller = TextEditingController();

  List<City> _results = [];
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();

    if (query.length < 2) {
      setState(() {
        _message = 'Type at least 2 characters';
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final results = await WeatherService.searchCity(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        if (results.isEmpty) {
          _message = 'City not found';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _message = 'Cannot search. Check your internet.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Supaya panel naik saat keyboard muncul
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose city',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: 'City name',
              prefixIcon: const Icon(Icons.location_city_outlined),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _search,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),

          if (_message != null && !_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_message!, style: const TextStyle(color: Colors.red)),
            ),

          if (_results.isNotEmpty && !_loading)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final city = _results[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: AppTheme.navy,
                    ),
                    title: Text(city.name),
                    subtitle: Text(city.subtitle),
                    onTap: () => Navigator.pop(context, city),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}