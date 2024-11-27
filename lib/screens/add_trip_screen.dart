import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/photo_service.dart';
import '../services/geo_service.dart';
import 'package:intl/intl.dart';
import '../widgets/app_drawer.dart';

class AddTripScreen extends StatelessWidget {
  final TextEditingController _nameController = TextEditingController();
  final PhotoService _photoService = PhotoService();
  final GeoService _geoService = GeoService();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Trip')),
      drawer: AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: '여행지 이름'),
            ),
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (picked != null) {
                  _startDate = picked;
                }
              },
              child: Text('여행 시작 날짜 선택'),
            ),
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: _startDate ?? DateTime.now(),
                  lastDate: DateTime(2101),
                );
                if (picked != null) {
                  _endDate = picked;
                }
              },
              child: Text('여행 종료 날짜 선택'),
            ),
            ElevatedButton(
              onPressed: () async {
                final tripName = _nameController.text.trim();
                if (tripName.isNotEmpty) {
                  await _addTripToFirestore(context, tripName);
                  Navigator.pop(context, true); // 성공 신호 반환
                }
              },
              child: Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTripToFirestore(BuildContext context, String tripName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final tripsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('MyTrips');

      final now = DateTime.now();
      final photoUrl = await _photoService.fetchPhoto(tripName);
      final coordinates = await _geoService.getCoordinates(tripName); // Geocoding API 호출

      final formatter = DateFormat('M월 d일');
      final startDateStr = _startDate != null ? formatter.format(_startDate!) : "미정";
      final endDateStr = _endDate != null ? formatter.format(_endDate!) : "미정";

      await tripsRef.add({
        "name": tripName,
        "dates": "$startDateStr ~ $endDateStr",
        "photo": photoUrl,
        "latitude": coordinates['latitude'], // 좌표 저장
        "longitude": coordinates['longitude'], // 좌표 저장
        "lastVisited": Timestamp.now(),
      });
      print('Trip added successfully');
    } catch (e) {
      print('여행지 추가 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('여행지 추가 실패: $e')),
      );
    }
  }
}
