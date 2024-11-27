import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
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
            title: Text('나의 여행 목록'),
            onTap: () {
              Navigator.pop(context); // 사이드바 닫기
              Navigator.pushNamed(context, '/myTrips');
            },
          ),
          ListTile(
            leading: Icon(Icons.add),
            title: Text('새로운 여행 추가'),
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
    );
  }
}
