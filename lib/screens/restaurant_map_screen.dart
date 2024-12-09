import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/place_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantMapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  RestaurantMapScreen({required this.latitude, required this.longitude});

  @override
  _RestaurantMapScreenState createState() => _RestaurantMapScreenState();
}

class _RestaurantMapScreenState extends State<RestaurantMapScreen> {
  final PlaceService placeService = PlaceService();
  Set<Marker> markers = {};
  Map<String, dynamic>? selectedPlace;

  @override
  void initState() {
    super.initState();
    fetchPlaces();
  }

  void fetchPlaces() async {
    final places = await placeService.fetchPlaces(
      latitude: widget.latitude,
      longitude: widget.longitude,
      keyword: 'food',
    );

    if (places.isNotEmpty) {
      setState(() {
        markers = places.map((place) {
          return Marker(
            markerId: MarkerId(place['name']),
            position: LatLng(place['lat'], place['lng']),
            onTap: () {
              setState(() {
                selectedPlace = place;
              });
            },
          );
        }).toSet();
      });
    }
  }

  Future<void> addToFavorites({
    required String placeId,
    required double latitude,
    required double longitude,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("사용자가 인증되지 않았습니다.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    try {
      // Place Details API를 호출하여 장소 세부 정보를 가져옵니다.
      final placeDetails = await placeService.fetchPlaceDetails(placeId);

      // user.uid 접근 시 null 안전 연산자를 사용하지 않아도 됨 (이미 null 체크 완료)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorite_restaurants')
          .add({
        'latitude': latitude,
        'longitude': longitude,
        'place_id': placeId, // place_id 추가
        'timestamp': FieldValue.serverTimestamp(), // 추가 데이터
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('찜한 장소가 저장되었습니다.')),
      );
    } catch (e) {
      print('찜하기 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('찜 목록 추가 중 문제가 발생했습니다.')),
      );
    }
  }


  Widget buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        double value = rating - index;
        if (value >= 1) {
          return Icon(Icons.star, color: Colors.amber, size: 20);
        } else if (value > 0) {
          return Icon(Icons.star_half, color: Colors.amber, size: 20);
        } else {
          return Icon(Icons.star_border, color: Colors.amber, size: 20);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('맛집 지도')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.latitude, widget.longitude),
              zoom: 14,
            ),
            markers: markers,
          ),

          if (selectedPlace != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 350,
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // 왼쪽 텍스트 정보
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedPlace!['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '평점: ${selectedPlace!['rating']}',
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(width: 8),
                              buildStarRating(selectedPlace!['rating']),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text('주소: ${selectedPlace!['address']}'),
                          SizedBox(height: 8),
                          Text(
                            '리뷰:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: (selectedPlace!['reviews'] as List).isNotEmpty
                                ? ListView.builder(
                              itemCount:
                              (selectedPlace!['reviews'] as List)
                                  .length,
                              itemBuilder: (context, index) {
                                final review =
                                selectedPlace!['reviews'][index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4.0),
                                  child: Text(
                                    '"${review['text'] ?? '리뷰 없음'}" - ${review['author_name'] ?? '익명'}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600]),
                                  ),
                                );
                              },
                            )
                                : Text(
                              '리뷰가 없습니다.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    // 오른쪽 대표 사진과 찜하기 버튼
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          selectedPlace!['photo_reference'] != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${selectedPlace!['photo_reference']}&key=${placeService.apiKey}',
                              width: double.infinity,
                              height: 250, // 사진 크기를 크게 설정
                              fit: BoxFit.cover,
                            ),
                          )
                              : Container(
                            height: 150,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (selectedPlace != null) {
                                addToFavorites(
                                  placeId: selectedPlace!['place_id'], // 명시적 인자 사용
                                  latitude: selectedPlace!['lat'],
                                  longitude: selectedPlace!['lng'],
                                );
                              }
                            },
                            icon: Icon(Icons.favorite, color: Colors.white),
                            label: Text('찜하기'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),

                        ],
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
