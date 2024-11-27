import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/my_trips_screen.dart';
import 'screens/add_trip_screen.dart';
import 'screens/trip_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(TravelMateApp());
}

class TravelMateApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TravelMate',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/', // 초기 화면
      routes: {
        '/': (context) => LoginScreen(), // 로그인 화면
        '/home': (context) => HomeScreen(), // 홈 화면
        '/myTrips': (context) => MyTripsScreen(), // 여행 목록 화면
        '/addTrip': (context) => AddTripScreen(), // 새 여행 추가 화면
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/tripDetail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => TripDetailScreen(trip: args),
          );
        }
        return null;
      },
    );
  }
}
