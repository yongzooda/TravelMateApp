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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '여행 일정: ${widget.trip['dates']}',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 16),
                  weatherData == null
                      ? Center(child: CircularProgressIndicator())
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '현재 날씨: ${weatherData!['weather'][0]['description']}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '온도: ${weatherData!['main']['temp']}°C',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '습도: ${weatherData!['main']['humidity']}%',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapScreen(
                            latitude: latitude,
                            longitude: longitude,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.map),
                    label: Text('여행지 지도 보기'),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RestaurantMapScreen(
                            latitude: latitude,
                            longitude: longitude,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.restaurant),
                    label: Text('맛집 지도 보기'),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LandmarkMapScreen(
                            latitude: latitude,
                            longitude: longitude,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.location_city),
                    label: Text('명소 지도 보기'),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AccommodationMapScreen(
                            latitude: latitude,
                            longitude: longitude,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.hotel),
                    label: Text('숙소 지도 보기'),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScheduleScreen(
                            latitude: latitude,
                            longitude: longitude,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.schedule),
                    label: Text('스케쥴 짜기'),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
