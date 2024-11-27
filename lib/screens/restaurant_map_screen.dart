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

  @override
  void initState() {
    super.initState();
    fetchRestaurants();
  }

  void fetchRestaurants() async {
    final places = await placeService.fetchPlaces(
      latitude: widget.latitude,
      longitude: widget.longitude,
      type: 'restaurant',
    );

    setState(() {
      markers = places
          .map((place) => Marker(
        markerId: MarkerId(place['name']),
        position: LatLng(place['lat'], place['lng']),
        infoWindow: InfoWindow(
          title: place['name'],
          snippet: '평점: ${place['rating']}',
        ),
      ))
          .toSet();
    });

    print('Markers: $markers');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('맛집 지도')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.latitude, widget.longitude),
          zoom: 14,
        ),
        markers: markers,
      ),
    );
  }
}
