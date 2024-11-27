import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  final Map<String, String> recentTrip = {
    'name': 'Barcelona',
    'photo': 'assets/barcelona.jpg',
    'dates': '4월 4일 ~ 4월 11일',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('홈 화면'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'TravelMate 메뉴',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('홈'),
              onTap: () {
                Navigator.pop(context); // 사이드바 닫기
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text('여행 목록'),
              onTap: () {
                Navigator.pop(context); // 사이드바 닫기
                Navigator.pushNamed(context, '/myTrips');
              },
            ),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('새 여행 추가'),
              onTap: () {
                Navigator.pop(context); // 사이드바 닫기
                Navigator.pushNamed(context, '/addTrip');
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('로그아웃'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pop(context); // 사이드바 닫기
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '환영합니다, ${FirebaseAuth.instance.currentUser?.email}님!',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Text(
              '최근 여행 기록',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/tripDetail',
                  arguments: recentTrip, // 여행 정보 전달
                );
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      recentTrip['photo']!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recentTrip['name']!,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(recentTrip['dates']!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
