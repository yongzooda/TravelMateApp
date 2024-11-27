import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;

  final LatLng _center = LatLng(41.3851, 2.1734);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('지도 및 동선')),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 12,
        ),
        markers: {
          Marker(
            markerId: MarkerId('맛집1'),
            position: LatLng(41.3851, 2.1734),
            infoWindow: InfoWindow(title: '맛집1'),
          ),
          Marker(
            markerId: MarkerId('명소1'),
            position: LatLng(41.4036, 2.1744),
            infoWindow: InfoWindow(title: '명소1'),
          ),
        },
      ),
    );
  }
}
