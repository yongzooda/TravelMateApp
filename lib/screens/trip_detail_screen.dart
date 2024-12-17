import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../services/photo_service.dart';
import 'map_screen.dart';
import 'restaurant_map_screen.dart';
import 'landmark_map_screen.dart';
import 'accommodation_map_screen.dart';
import 'package:finalproject/screens/schedule_screen.dart';

import '../widgets/app_drawer.dart';

class TripDetailScreen extends StatefulWidget {
  final Map<String, dynamic> trip;

  const TripDetailScreen({Key? key, required this.trip}) : super(key: key);

  @override
  _TripDetailScreenState createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final WeatherService weatherService = WeatherService();
  final PhotoService photoService = PhotoService();
  Map<String, dynamic>? weatherData;
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    fetchWeather();
    fetchPhoto();
    debugFirestoreData();
  }

  void fetchWeather() async {
    try {
      final data = await weatherService.fetchWeather(widget.trip['name']);
      setState(() {
        weatherData = data;
      });
    } catch (e) {
      print('Failed to fetch weather data: $e');
    }
  }

  void fetchPhoto() async {
    try {
      final url = await photoService.fetchPhoto(widget.trip['name']);
      setState(() {
        photoUrl = url;
      });
    } catch (e) {
      print('Failed to fetch photo: $e');
    }
  }

  void debugFirestoreData() {
    print('Trip Data: ${widget.trip}');
    print('Latitude: ${widget.trip['latitude']}');
    print('Longitude: ${widget.trip['longitude']}');
  }

  @override
  Widget build(BuildContext context) {
    final latitude = widget.trip['latitude'] ?? 0.0;
    final longitude = widget.trip['longitude'] ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.trip['name']} 여행')),
      drawer: AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 상단 이미지 섹션
            Stack(
              children: [
                photoUrl != null
                    ? Image.network(
                  photoUrl!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                )
                    : Container(
                  width: double.infinity,
                  height: 250,
                  color: Colors.grey[300],
                  child: Center(child: CircularProgressIndicator()),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Text(
                    widget.trip['name'] ?? '여행지 이름 없음',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 4.0,
                          color: Colors.black,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 여행 일정 및 날씨 섹션
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '여행 일정: ${widget.trip['dates']}',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Divider(),
                      weatherData == null
                          ? Center(child: CircularProgressIndicator())
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Icon(Icons.wb_sunny, color: Colors.orange),
                              SizedBox(height: 4),
                              Text(
                                  '날씨: ${weatherData!['weather'][0]['description']}'),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(Icons.thermostat,
                                  color: Colors.redAccent),
                              SizedBox(height: 4),
                              Text('온도: ${weatherData!['main']['temp']}°C'),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(Icons.water_drop,
                                  color: Colors.blueAccent),
                              SizedBox(height: 4),
                              Text('습도: ${weatherData!['main']['humidity']}%'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 버튼 섹션 - Grid로 배치
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 3 / 1.1,
                children: [
                  _buildCustomButton(
                      context, '여행지 지도 보기', Icons.map, MapScreen(latitude: latitude, longitude: longitude)),
                  _buildCustomButton(
                      context, '맛집 지도 보기', Icons.restaurant, RestaurantMapScreen(latitude: latitude, longitude: longitude)),
                  _buildCustomButton(
                      context, '명소 지도 보기', Icons.location_city, LandmarkMapScreen(latitude: latitude, longitude: longitude)),
                  _buildCustomButton(
                      context, '숙소 지도 보기', Icons.hotel, AccommodationMapScreen(latitude: latitude, longitude: longitude)),
                  _buildCustomButton(
                      context, '스케쥴 짜기', Icons.schedule, ScheduleScreen(latitude: latitude, longitude: longitude)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 버튼 커스텀 위젯
  Widget _buildCustomButton(BuildContext context, String title, IconData icon, Widget screen) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blueAccent, size: 28),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
