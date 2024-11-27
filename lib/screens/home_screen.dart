import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? recentTrip;

  @override
  void initState() {
    super.initState();
    fetchRecentTrip();
  }

  Future<void> fetchRecentTrip() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Error: No authenticated user');
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('MyTrips')
          .orderBy('lastVisited', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          recentTrip = data; // 데이터를 그대로 저장
        });
      } else {
        setState(() {
          recentTrip = null;
        });
      }
    } catch (e) {
      print('Failed to fetch recent trip: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('홈 화면'),
      ),
      drawer: AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '환영합니다, ${FirebaseAuth.instance.currentUser?.email ?? '사용자'}님!',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Text(
              '최근 여행 기록',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            recentTrip == null
                ? Center(
              child: Text(
                '최근 여행 기록이 없습니다.',
                style: TextStyle(fontSize: 16),
              ),
            )
                : GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/tripDetail',
                  arguments: recentTrip, // 전체 데이터를 전달
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
                    Image.network(
                      recentTrip!['photo'],
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
                            recentTrip!['name'],
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(recentTrip!['dates']),
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
