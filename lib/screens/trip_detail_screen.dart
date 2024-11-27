import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import 'map_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final Map<String, String> trip;

  TripDetailScreen({required this.trip});

  @override
  _TripDetailScreenState createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final WeatherService weatherService = WeatherService();
  Map<String, dynamic>? weatherData;

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  void fetchWeather() async {
    try {
      final data = await weatherService.fetchWeather(widget.trip['name']!);
      setState(() {
        weatherData = data;
      });
    } catch (e) {
      print('Failed to fetch weather data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.trip['name']} 여행')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(widget.trip['photo']!, width: double.infinity, height: 200, fit: BoxFit.cover),
            SizedBox(height: 16),
            Text(
              '${widget.trip['name']} 여행',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('날짜: ${widget.trip['dates']}'),
            SizedBox(height: 16),
            weatherData == null
                ? CircularProgressIndicator()
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('현재 날씨: ${weatherData!['weather'][0]['description']}'),
                Text('온도: ${weatherData!['main']['temp']}°C'),
                Text('습도: ${weatherData!['main']['humidity']}%'),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MapScreen()),
                );
              },
              child: Text('지도 및 동선 보기'),
            ),
          ],
        ),
      ),
    );
  }
}
