import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/photo_service.dart';
import '../services/geo_service.dart';
import '../services/place_service.dart'; // PlaceService 추가
import '../widgets/app_drawer.dart';

class AddTripScreen extends StatefulWidget {
  @override
  _AddTripScreenState createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final TextEditingController _nameController = TextEditingController();
  final PhotoService _photoService = PhotoService();
  final GeoService _geoService = GeoService();
  final PlaceService _placeService = PlaceService(); // PlaceService 인스턴스 생성

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Trip'),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: AppDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "여행지 검색",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildSearchField(), // 검색창 UI
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDateSelector("여행 시작일", _startDate, () => _pickDate(true)),
                          _buildDateSelector("여행 종료일", _endDate, () => _pickDate(false)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildAddButton(context),
    );
  }

  // 여행지 검색 Autocomplete
  Widget _buildSearchField() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty) return const [];
        final suggestions = await _placeService.fetchPlaceSuggestions(textEditingValue.text);
        return suggestions.map((place) => place['description'] as String);
      },
      onSelected: (String selection) {
        setState(() {
          _nameController.text = selection; // 선택된 여행지 설정
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: "여행지를 검색하세요",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onEditingComplete: onEditingComplete,
        );
      },
    );
  }

  // 날짜 선택 버튼
  Widget _buildDateSelector(String title, DateTime? date, VoidCallback onPressed) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          SizedBox(height: 6),
          OutlinedButton(
            onPressed: onPressed,
            child: Text(
              date != null ? DateFormat('yyyy-MM-dd').format(date) : '날짜 선택',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // 여행 추가 버튼
  Widget _buildAddButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _submitTrip,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.blueAccent,
          ),
          child: Text("여행 추가하기", style: TextStyle(fontSize: 18, color: Colors.white)),
        ),
      ),
    );
  }

  // 날짜 선택
  Future<void> _pickDate(bool isStartDate) async {
    if (!isStartDate && _startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("먼저 여행 시작일을 선택해주세요.")),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? DateTime.now() : _startDate!.add(Duration(days: 1)),
      firstDate: isStartDate ? DateTime.now() : _startDate!,
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null; // 종료일 리셋
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Firestore에 여행지 추가
  void _submitTrip() async {
    final tripName = _nameController.text.trim();
    if (tripName.isEmpty || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("모든 정보를 입력해주세요.")),
      );
      return;
    }

    await _addTripToFirestore(tripName);
    Navigator.pop(context, true);
  }

  Future<void> _addTripToFirestore(String tripName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final tripsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('MyTrips');

      final photoUrl = await _photoService.fetchPhoto(tripName);
      final coordinates = await _geoService.getCoordinates(tripName);

      await tripsRef.add({
        "name": tripName,
        "dates": "${DateFormat('yyyy-MM-dd').format(_startDate!)} ~ ${DateFormat('yyyy-MM-dd').format(_endDate!)}",
        "photo": photoUrl,
        "latitude": coordinates['latitude'],
        "longitude": coordinates['longitude'],
        "lastVisited": Timestamp.now(),
      });

      print("여행지가 추가되었습니다.");
    } catch (e) {
      print("여행지 추가 실패: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('여행지 추가 실패: $e')),
      );
    }
  }
}
