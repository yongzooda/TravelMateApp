import 'dart:convert';
import 'package:http/http.dart' as http;

class PlaceService {
  final String apiKey = 'AIzaSyCR_YT9dN3ei0ZBsiui-9UX8Vj6POVYEHQ'; // Google Maps API 키

  Future<List<Map<String, dynamic>>> fetchPlaces({
    required double latitude,
    required double longitude,
    required String type,
  }) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=5000&type=$type&key=$apiKey';

    try {
      print('Requesting URL: $url');
      final response = await http.get(Uri.parse(url));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Response Data: ${data['results']}');

        if (data['results'] != null) {
          // 데이터 필터링 및 정렬
          final results = (data['results'] as List)
              .where((place) =>
          place['geometry'] != null &&
              place['geometry']['location'] != null &&
              place['rating'] != null)
              .map((place) => {
            'name': place['name'],
            'rating': place['rating'],
            'lat': place['geometry']['location']['lat'],
            'lng': place['geometry']['location']['lng'],
          })
              .toList();

          results.sort((a, b) => b['rating'].compareTo(a['rating']));
          return results.take(5).toList();
        }
      } else {
        print('Failed to fetch places: ${response.statusCode}');
      }
    } catch (e,stacktrace) {
      print('Error fetching places: $e');
      print('Stacktrace: $stacktrace');
    }

    return [];
  }
}