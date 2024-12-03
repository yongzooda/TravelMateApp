import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/place_service.dart';

class AccommodationMapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  AccommodationMapScreen({required this.latitude, required this.longitude});

  @override
  _AccommodationMapScreenState createState() =>
      _AccommodationMapScreenState();
}

class _AccommodationMapScreenState extends State<AccommodationMapScreen> {
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
      keyword: 'hotel',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('숙소 지도')),
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
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedPlace!['name'],
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('평점: ${selectedPlace!['rating']}'),
                    Text('주소: ${selectedPlace!['address']}'),
                    if (selectedPlace!['photo_reference'] != null)
                      Image.network(
                        'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${selectedPlace!['photo_reference']}&key=${placeService.apiKey}',
                        fit: BoxFit.cover,
                      )
                    else
                      Icon(Icons.image_not_supported),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
