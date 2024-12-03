import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_drawer.dart';

class MyTripsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Trips')),
      drawer: AppDrawer(), // 공통 Drawer 추가
      body: StreamBuilder<QuerySnapshot>(
        stream: _getTripsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator()); // 데이터 로딩 중
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('데이터를 불러오는 중 오류가 발생했습니다.'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                '저장된 여행지가 없습니다.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final trips = snapshot.data!.docs;

          return ListView.builder(
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final tripDoc = trips[index]; // 문서 참조
              final tripData = tripDoc.data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  leading: tripData['photo'] != null
                      ? Image.network(
                    tripData['photo'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.image_not_supported);
                    },
                  )
                      : Icon(Icons.image),
                  title: Text(tripData['name'] ?? '이름 없음'),
                  subtitle: Text(tripData['dates'] ?? '날짜 없음'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _confirmDelete(context, tripDoc.id); // 삭제 확인 다이얼로그 호출
                    },
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/tripDetail',
                      arguments: {
                        'name': tripData['name'],
                        'dates': tripData['dates'],
                        'photo': tripData['photo'],
                        'latitude': tripData['latitude'], // 위도 추가
                        'longitude': tripData['longitude'], // 경도 추가
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Firestore의 MyTrips 컬렉션을 스트림으로 가져오기
  Stream<QuerySnapshot> _getTripsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('사용자가 인증되지 않았습니다.');
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('MyTrips')
        .orderBy('lastVisited', descending: true)
        .snapshots();
  }

  // 여행지 삭제 확인 다이얼로그
  void _confirmDelete(BuildContext context, String tripId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('여행 삭제'),
          content: Text('정말로 이 여행을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteTrip(tripId);
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  // 여행지 삭제 함수
  Future<void> _deleteTrip(String tripId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('사용자가 인증되지 않았습니다.');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('MyTrips')
          .doc(tripId)
          .delete();

      print('여행지가 성공적으로 삭제되었습니다.');
    } catch (e) {
      print('여행지 삭제 실패: $e');
    }
  }
}
