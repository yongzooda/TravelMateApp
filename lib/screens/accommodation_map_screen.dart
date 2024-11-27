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

  @override
  void initState() {
    super.initState();
    fetchAccommodations();
  }

  void fetchAccommodations() async {
    final places = await placeService.fetchPlaces(
      latitude: widget.latitude,
      longitude: widget.longitude,
      type: 'lodging',
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
      appBar: AppBar(title: Text('숙소 지도')),
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
