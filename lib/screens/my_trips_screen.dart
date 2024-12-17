import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_drawer.dart';

class MyTripsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Trips'),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: AppDrawer(),
      body: Container(
        color: Colors.grey[100], // 배경색 추가
        child: StreamBuilder<QuerySnapshot>(
          stream: _getTripsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  '데이터를 불러오는 중 오류가 발생했습니다.',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  '저장된 여행지가 없습니다.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }

            final trips = snapshot.data!.docs;

            return ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final tripDoc = trips[index];
                final tripData = tripDoc.data() as Map<String, dynamic>;

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: tripData['photo'] != null
                          ? Image.network(
                        tripData['photo'],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                          : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: Icon(Icons.image, size: 40),
                      ),
                    ),
                    title: Text(
                      tripData['name'] ?? '이름 없음',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      tripData['dates'] ?? '날짜 없음',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        _confirmDelete(context, tripDoc.id);
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
                          'latitude': tripData['latitude'],
                          'longitude': tripData['longitude'],
                        },
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
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
                Navigator.of(context).pop();
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteTrip(tripId);
                Navigator.of(context).pop();
              },
              child: Text('삭제', style: TextStyle(color: Colors.red)),
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
