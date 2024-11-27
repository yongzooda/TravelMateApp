import 'package:flutter/material.dart';

class MyTripsScreen extends StatelessWidget {
  final List<Map<String, String>> allTrips = [
    {'name': 'Barcelona', 'date': '4월 4일 ~ 4월 11일', 'photo': 'barcelona.jpg'},
    {'name': 'Paris', 'date': '3월 28일 ~ 4월 4일', 'photo': 'paris.jpg'},
    {'name': 'Rome', 'date': '5월 1일 ~ 5월 7일', 'photo': 'rome.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Trips')),
      body: ListView.builder(
        itemCount: allTrips.length,
        itemBuilder: (context, index) {
          final trip = allTrips[index];
          return Card(
            child: ListTile(
              leading: Image.asset(trip['photo'] ?? '', width: 50, height: 50, fit: BoxFit.cover),
              title: Text(trip['name'] ?? ''),
              subtitle: Text(trip['date'] ?? ''),
              onTap: () {
                // 여행 상세 화면으로 이동
                Navigator.pushNamed(context, '/tripDetail', arguments: trip);
              },
            ),
          );
        },
      ),
    );
  }
}
