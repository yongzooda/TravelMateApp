import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/place_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LandmarkMapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  LandmarkMapScreen({required this.latitude, required this.longitude});

  @override
  _LandmarkMapScreenState createState() => _LandmarkMapScreenState();
}

class _LandmarkMapScreenState extends State<LandmarkMapScreen> {
  final PlaceService placeService = PlaceService();
  Set<Marker> markers = {};
  Map<String, dynamic>? selectedPlace;
  bool isFavorite = false; // 찜 여부 상태

  @override
  void initState() {
    super.initState();
    fetchPlaces();
  }

  // 명소 가져오기
  void fetchPlaces() async {
    final places = await placeService.fetchPlaces(
      latitude: widget.latitude,
      longitude: widget.longitude,
      keyword: 'landmark',
    );

    if (places.isNotEmpty) {
      setState(() {
        markers = places.map((place) {
          return Marker(
            markerId: MarkerId(place['name']),
            position: LatLng(place['lat'], place['lng']),
            onTap: () async {
              setState(() {
                selectedPlace = place;
              });
              // 선택된 장소가 찜 목록에 있는지 확인
              await checkFavorite(place['place_id']);
            },
          );
        }).toSet();
      });
    }
  }

  // 찜 여부 확인
  Future<void> checkFavorite(String placeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorite_landmarks')
        .where('place_id', isEqualTo: placeId)
        .get();

    setState(() {
      isFavorite = snapshot.docs.isNotEmpty;
    });
  }

  // 찜하기 또는 찜하기 취소
  Future<void> toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || selectedPlace == null) return;

    final placeId = selectedPlace!['place_id'];

    try {
      if (isFavorite) {
        // 찜하기 취소
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorite_landmarks')
            .where('place_id', isEqualTo: placeId)
            .get();

        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }

        setState(() {
          isFavorite = false;
        });
      } else {
        // 찜하기 추가
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorite_landmarks')
            .add({
          'place_id': placeId,
          'latitude': selectedPlace!['lat'],
          'longitude': selectedPlace!['lng'],
          'timestamp': FieldValue.serverTimestamp(),
        });

        setState(() {
          isFavorite = true;
        });
      }
    } catch (e) {
      print('찜하기 동작 실패: $e');
    }
  }

  // 평점 UI 빌드
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
      appBar: AppBar(title: Text('명소 지도')),
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
                                '평점: ${selectedPlace!['rating'] ?? 'N/A'}',
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(width: 8),
                              buildStarRating(
                                  selectedPlace!['rating'] ?? 0.0),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '주소: ${selectedPlace!['address'] ?? 'N/A'}',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '전화번호: ${selectedPlace!['formatted_phone_number'] ?? '전화번호 없음'}',
                            style: TextStyle(fontSize: 14, color: Colors.blue),
                          ),
                          SizedBox(height: 8),
                          Expanded(
                            child: (selectedPlace!['reviews'] as List?)
                                ?.isNotEmpty ??
                                false
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
                    // 오른쪽 대표 사진과 버튼
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
                              height: 260,
                              fit: BoxFit.cover,
                            ),
                          )
                              : Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: Icon(Icons.image_not_supported),
                          ),
                          SizedBox(height: 8),
                          // 찜하기 및 닫기 버튼
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                onPressed: toggleFavorite,
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                ),
                                label: Text(
                                    isFavorite ? '찜하기 취소' : '찜하기'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFavorite
                                      ? Colors.redAccent
                                      : Colors.blueAccent,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    selectedPlace = null;
                                  });
                                },
                                child: Text('닫기'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey),
                              ),
                            ],
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
