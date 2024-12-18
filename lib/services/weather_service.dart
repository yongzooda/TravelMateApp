import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = '7e17f7df34530fa90c0555ed07c83844';

  // 위도와 경도를 기반으로 날씨 데이터 가져오기
  Future<Map<String, dynamic>> fetchWeatherByCoordinates(
      double latitude, double longitude) async {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric&lang=kr');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body); // JSON 데이터를 Map으로 변환
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      print('Error fetching weather: $e');
      throw Exception('Error fetching weather');
    }
  }
}
