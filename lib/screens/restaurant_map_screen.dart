import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/place_service.dart';

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

  Widget buildStarRating(double rating) {
    return Row(
      children: List.generate(
        5,
            (index) => Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        ),
      ),
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
                height: 300, // 사이드바 높이 조정
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
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
                            '대표 메뉴: 김치찌개, 삼겹살', // 예시 메뉴
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '리뷰: 정말 맛있어요!', // 예시 리뷰
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: selectedPlace!['photo_reference'] != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${selectedPlace!['photo_reference']}&key=${placeService.apiKey}',
                          height: 120, // 고정 높이
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                          : Container(
                        height: 120,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey[700],
                        ),
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
