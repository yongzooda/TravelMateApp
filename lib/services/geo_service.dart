import 'dart:convert';
import 'package:http/http.dart' as http;

class GeoService {
  final String apiKey = 'AIzaSyCR_YT9dN3ei0ZBsiui-9UX8Vj6POVYEHQ'; // 여기에 Google API 키를 입력하세요.

  Future<Map<String, double>> getCoordinates(String location) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(location)}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      print('GeoService Response: ${response.body}'); // 응답 내용을 출력

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          final coordinates = data['results'][0]['geometry']['location'];
          print('Coordinates found: $coordinates'); // 좌표 출력
          return {
            'latitude': coordinates['lat'],
            'longitude': coordinates['lng'],
          };
        } else {
          print('No results found for location: $location');
        }
      } else {
        print('Failed to fetch coordinates: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching coordinates: $e');
    }

    // 기본 좌표 (실패 시)
    return {
      'latitude': 0.0,
      'longitude': 0.0,
    };
  }

}
