import 'dart:convert';
import 'package:http/http.dart' as http;

class PlaceService {
  final String apiKey = 'AIzaSyCR_YT9dN3ei0ZBsiui-9UX8Vj6POVYEHQ'; // Google Maps API 키

  Future<List<Map<String, dynamic>>> fetchPlaces({
    required double latitude,
    required double longitude,
    String? keyword, // Optional keyword for filtering
  }) async {
    final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$latitude,$longitude&radius=5000'
        '${keyword != null ? '&keyword=$keyword' : ''}'
        '&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      print('Request URL: $url');
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Full API Response: ${data['results']}');

        if (data['results'] != null) {
          final results = (data['results'] as List)
              .map((place) => {
            'name': place['name'],
            'rating': place['rating'] ?? 0.0,
            'lat': place['geometry']['location']['lat'],
            'lng': place['geometry']['location']['lng'],
            'photo_reference': place['photos'] != null &&
                place['photos'].isNotEmpty
                ? place['photos'][0]['photo_reference']
                : null,
            'address': place['vicinity'],
          })
              .toList();

          print('Filtered Results: $results');
          results.sort((a, b) => b['rating'].compareTo(a['rating']));
          return results;
        }
      } else {
        print('Failed to fetch places: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching places: $e');
    }

    return [];
  }
}
