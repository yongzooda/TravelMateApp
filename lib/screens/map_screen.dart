import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  MapScreen({required this.latitude, required this.longitude});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  Map<String, dynamic>? selectedPlace;

  final String apiKey = 'AIzaSyCR_YT9dN3ei0ZBsiui-9UX8Vj6POVYEHQ';

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  // Google Places API로 장소 세부정보 가져오기
  Future<Map<String, dynamic>> fetchPlaceDetails(String placeId) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result'] ?? {};
      } else {
        print('Failed to fetch place details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching place details: $e');
    }
    return {};
  }

  // 데이터베이스에서 찜한 장소 가져오기
  Future<void> fetchFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final categories = [
      'favorite_restaurants',
      'favorite_landmarks',
      'favorite_accommodations'
    ];

    List<Map<String, dynamic>> allPlaces = [];

    try {
      for (String category in categories) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection(category)
            .get();

        final places = snapshot.docs.map((doc) => doc.data()).toList();
        allPlaces.addAll(places);
      }

      List<Marker> fetchedMarkers = [];
      for (var place in allPlaces) {
        if (place['place_id'] != null) {
          final details = await fetchPlaceDetails(place['place_id']);
          if (details.isNotEmpty) {
            fetchedMarkers.add(
              Marker(
                markerId: MarkerId('${place['latitude']}_${place['longitude']}'),
                position: LatLng(place['latitude'], place['longitude']),
                onTap: () {
                  setState(() {
                    selectedPlace = details; // 선택된 장소 저장
                  });
                },
              ),
            );
          }
        }
      }

      setState(() {
        markers = fetchedMarkers.toSet();
      });
    } catch (e) {
      print('Error fetching favorites: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('찜한 장소 지도')),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.latitude, widget.longitude),
              zoom: 12,
            ),
            markers: markers,
          ),
          if (selectedPlace != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 350,
                margin: const EdgeInsets.all(8.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8.0,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 왼쪽 텍스트 정보
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedPlace!['name'] ?? '알 수 없는 장소',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '평점: ${selectedPlace!['rating']?.toString() ?? '평점 없음'}',
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(width: 8),
                              Row(
                                children: List.generate(
                                  5,
                                      (index) => Icon(
                                    index <
                                        (selectedPlace!['rating']
                                            ?.round() ??
                                            0)
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '주소: ${selectedPlace!['formatted_address'] ?? '주소 정보 없음'}',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '리뷰:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: (selectedPlace!['reviews'] as List).length,
                              itemBuilder: (context, index) {
                                final review = (selectedPlace!['reviews'] as List)[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Text(
                                    '"${review['text']}" - ${review['author_name']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    // 오른쪽 대표 사진
                    Expanded(
                      flex: 2,
                      child: selectedPlace!['photos'] != null &&
                          selectedPlace!['photos'].isNotEmpty
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${selectedPlace!['photos'][0]['photo_reference']}&key=$apiKey',
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                        ),
                      )
                          : Container(
                        height: 250,
                        color: Colors.grey[300],
                        child: Icon(Icons.image_not_supported),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
