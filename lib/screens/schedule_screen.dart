import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScheduleScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  ScheduleScreen({required this.latitude, required this.longitude});

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _scheduleList = [];
  Map<String, dynamic>? _selectedPlace;
  LatLng? _selectedMarkerPosition; // 마커 위치 저장
  final String apiKey = 'AIzaSyCR_YT9dN3ei0ZBsiui-9UX8Vj6POVYEHQ';

  @override
  void initState() {
    super.initState();
    fetchFavoritePlaces();
  }

  // Firestore에서 찜한 장소 불러오기
  void fetchFavoritePlaces() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    List<Map<String, dynamic>> places = [];
    final categories = ['favorite_restaurants', 'favorite_landmarks', 'favorite_accommodations'];

    for (String category in categories) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection(category)
          .get();

      for (var doc in snapshot.docs) {
        places.add({
          'place_id': doc['place_id'],
          'lat': doc['latitude'],
          'lng': doc['longitude']
        });
      }
    }

    setState(() {
      _markers = places.map((place) {
        return Marker(
          markerId: MarkerId(place['place_id']),
          position: LatLng(place['lat'], place['lng']),
          onTap: () async {
            final details = await fetchPlaceDetails(place['place_id']);
            setState(() {
              _selectedPlace = details;
              _selectedMarkerPosition = LatLng(place['lat'], place['lng']);
            });
          },
        );
      }).toSet();
    });
  }

  // Google Places API로 장소 세부정보 불러오기
  Future<Map<String, dynamic>> fetchPlaceDetails(String placeId) async {
    final url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result'] ?? {};
      }
    } catch (e) {
      print('Error fetching place details: $e');
    }
    return {};
  }

  // 스케줄에 추가
  void addToSchedule(Map<String, dynamic> place) {
    setState(() {
      _scheduleList.add({
        'name': place['name'] ?? '알 수 없는 장소',
        'lat': place['geometry']['location']['lat'],
        'lng': place['geometry']['location']['lng']
      });
      _selectedPlace = null; // 인포창 닫기
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${place['name'] ?? '알 수 없는 장소'}가 스케줄에 추가되었습니다.')),
    );
  }

  // 커스텀 인포창 위젯
  Widget _buildCustomInfoWindow() {
    if (_selectedPlace == null || _selectedMarkerPosition == null) return SizedBox();

    Future<ScreenCoordinate> getMarkerScreenPosition() async {
      return await _mapController.getScreenCoordinate(_selectedMarkerPosition!);
    }

    return FutureBuilder<ScreenCoordinate>(
      future: getMarkerScreenPosition(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();

        final screenPosition = snapshot.data!;
        final left = screenPosition.x.toDouble() - 160; // 인포창 너비 절반 조정
        final top = screenPosition.y.toDouble() - 250;  // 마커 위로 이동

        return Positioned(
          left: left,
          top: top,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(maxWidth: 320), // 최대 너비 설정
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          _selectedPlace!['name'] ?? '알 수 없는 장소',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            _selectedPlace = null;
                            _selectedMarkerPosition = null;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    _selectedPlace!['formatted_address'] ?? '주소 정보 없음',
                    style: TextStyle(fontSize: 13, height: 1.2), // 줄 간격 조정
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '평점: ${_selectedPlace!['rating'] ?? '등록된 평점 없음'}   전화번호: ${_selectedPlace!['formatted_phone_number'] ?? '없음'}',
                    style: TextStyle(fontSize: 13, height: 1.2),
                  ),
                  SizedBox(height: 8),
                  _selectedPlace!['photos'] != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${_selectedPlace!['photos'][0]['photo_reference']}&key=$apiKey',
                      width: 300, // 너비를 인포창에 맞춤
                      height: 160, // 사진 높이 설정
                      fit: BoxFit.cover,
                    ),
                  )
                      : Container(
                    height: 160,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: Icon(Icons.image_not_supported, size: 50),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      ),
                      onPressed: () => addToSchedule(_selectedPlace!),
                      child: Text('스케줄에 추가', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('스케줄 페이지')),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.latitude, widget.longitude),
              zoom: 12,
            ),
            markers: _markers,
          ),
          _buildCustomInfoWindow(),
          Positioned(
            bottom: 0,
            child: Container(
              color: Colors.white,
              height: 200,
              width: MediaQuery.of(context).size.width,
              child: ListView.builder(
                itemCount: _scheduleList.length,
                itemBuilder: (context, index) {
                  final place = _scheduleList[index];
                  return ListTile(
                    title: Text(place['name']),
                    subtitle: Text('위도: ${place['lat']}, 경도: ${place['lng']}'),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
