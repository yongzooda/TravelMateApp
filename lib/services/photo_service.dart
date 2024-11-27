import 'dart:convert';
import 'package:http/http.dart' as http;

class PhotoService {
  Future<String> fetchPhoto(String query) async {
    try {
      final apiKey = 'C8RZzLIVgJOMiaFZ83zvm81O17mghRmZGmZf6A1C4r4';
      final url =
          'https://api.unsplash.com/search/photos?query=$query&client_id=$apiKey';

      print('Fetching photo for query: $query');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          return data['results'][0]['urls']['regular'];
        } else {
          print('No results found for query: $query. Using fallback query.');
          // 대체 검색어로 다시 검색
          final fallbackUrl =
              'https://api.unsplash.com/search/photos?query=travel&client_id=$apiKey';
          final fallbackResponse = await http.get(Uri.parse(fallbackUrl));

          if (fallbackResponse.statusCode == 200) {
            final fallbackData = json.decode(fallbackResponse.body);
            if (fallbackData['results'].isNotEmpty) {
              return fallbackData['results'][0]['urls']['regular'];
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching photo: $e');
    }

    // 기본 이미지 반환
    return 'https://example.com/default.jpg';
  }

}
