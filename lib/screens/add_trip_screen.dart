import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/photo_service.dart';
import '../services/geo_service.dart';
import 'package:intl/intl.dart';
import '../widgets/app_drawer.dart';

class AddTripScreen extends StatefulWidget {
  @override
  _AddTripScreenState createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final TextEditingController _nameController = TextEditingController();
  final PhotoService _photoService = PhotoService();
  final GeoService _geoService = GeoService();
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
              // 여행지 입력 카드
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
                        "여행지 이름",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: "예: 서울, 파리, 부산 등",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // 날짜 선택 버튼
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDateSelector(
                              "여행 시작일", _startDate, () => _pickDate(true)),
                          _buildDateSelector(
                              "여행 종료일", _endDate, () => _pickDate(false)),
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

  // 날짜 선택 버튼
  Widget _buildDateSelector(
      String title, DateTime? date, VoidCallback onPressed) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          SizedBox(height: 6),
          OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              date != null ? DateFormat('yyyy-MM-dd').format(date) : '날짜 선택',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // "추가" 버튼 하단 고정
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
          child: Text(
            "여행 추가하기",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: isStartDate ? DateTime.now() : _startDate ?? DateTime.now(),
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
        "dates":
        "${DateFormat('yyyy-MM-dd').format(_startDate!)} ~ ${DateFormat('yyyy-MM-dd').format(_endDate!)}",
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
