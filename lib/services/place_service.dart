import 'dart:convert';
import 'package:http/http.dart' as http;

class PlaceService {
  final String apiKey = 'AIzaSyCR_YT9dN3ei0ZBsiui-9UX8Vj6POVYEHQ'; // Google Maps API 키

  // Place Details API 호출
  Future<Map<String, dynamic>> fetchPlaceDetails(String placeId) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result']; // Place Details API의 'result' 반환
      } else {
        print('Failed to fetch place details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching place details: $e');
    }

    return {};
  }

  // Nearby Search API 호출 + Place Details 데이터 병합
  Future<List<Map<String, dynamic>>> fetchPlaces({
    required double latitude,
    required double longitude,
    String? keyword,
  }) async {
    final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$latitude,$longitude&radius=5000'
        '${keyword != null ? '&keyword=$keyword' : ''}'
        '&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['results'] != null) {
          final results = (data['results'] as List);
          final detailedPlaces = await Future.wait(results.map((place) async {
            final details = await fetchPlaceDetails(place['place_id']);
            return {
              'name': place['name'],
              'place_id': place['place_id'], // place_id 추가
              'rating': place['rating'] ?? 0.0,
              'lat': place['geometry']['location']['lat'],
              'lng': place['geometry']['location']['lng'],
              'photo_reference': place['photos'] != null &&
                  place['photos'].isNotEmpty
                  ? place['photos'][0]['photo_reference']
                  : null,
              'address': place['vicinity'],
              'reviews': details['reviews'] ?? [],
            };
          }));

          return detailedPlaces;
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
