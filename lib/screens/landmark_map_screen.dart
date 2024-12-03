import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/place_service.dart';

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

  @override
  void initState() {
    super.initState();
    fetchPlaces();
  }

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
      children: List.generate(5, (index) {
        double value = rating - index;
        if (value >= 1) {
          // 별이 완전히 채워진 경우
          return Icon(Icons.star, color: Colors.amber, size: 20);
        } else if (value > 0) {
          // 별이 절반만 채워진 경우
          return Icon(Icons.star_half, color: Colors.amber, size: 20);
        } else {
          // 별이 비어있는 경우
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
                height: 300,
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
                            '리뷰:',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: (selectedPlace!['reviews'] as List).isNotEmpty
                                ? ListView.builder(
                              itemCount: (selectedPlace!['reviews'] as List).length,
                              itemBuilder: (context, index) {
                                final review = selectedPlace!['reviews'][index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Text(
                                    '"${review['text'] ?? '리뷰 없음'}" - ${review['author_name'] ?? '익명'}',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600]),
                                  ),
                                );
                              },
                            )
                                : Text('리뷰가 없습니다.', style: TextStyle(color: Colors.grey)),
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

                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                          : Container(
                        height: 250,
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

