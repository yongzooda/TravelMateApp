import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = '7e17f7df34530fa90c0555ed07c83844';

  Future<Map<String, dynamic>> fetchWeather(String cityName) async {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$apiKey&units=metric&lang=kr');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body); // JSON 데이터를 Map으로 변환
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}
