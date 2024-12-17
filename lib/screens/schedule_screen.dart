import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class ScheduleScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  ScheduleScreen({required this.latitude, required this.longitude});

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _scheduleList = [];
  Map<String, dynamic>? _selectedPlace;
  LatLng? _selectedMarkerPosition; // 마커 위치 저장
  final String apiKey = 'AIzaSyCR_YT9dN3ei0ZBsiui-9UX8Vj6POVYEHQ';


  @override
  void initState() {
    super.initState();
    fetchFavoritePlaces();
  }

  // 경로 초기화 및 최적화 경로를 표시할 변수들
  LatLng? _startPoint; // 출발지
  LatLng? _endPoint; // 목적지
  Set<Polyline> _polylines = {}; // 최적화 경로를 저장하는 폴리라인
  List<LatLng> _routeCoords = []; // 폴리라인 좌표 리스트
  String selectedMode = 'driving'; // 기본 경로 모드 (자동차)

  // Snap to Roads API를 사용하여 좌표를 도로 위로 스냅
  Future<LatLng> snapToRoad(LatLng point) async {
    final url =
        'https://roads.googleapis.com/v1/snapToRoads?path=${point.latitude},${point.longitude}&key=$apiKey';
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);
    if (data['snappedPoints'] != null) {
      final snapped = data['snappedPoints'][0]['location'];
      return LatLng(snapped['latitude'], snapped['longitude']);
    }
    return point; // 실패 시 원래 좌표 반환
  }
  Future<List<LatLng>> snapToRoadsForWaypoints(List<Map<String, dynamic>> waypoints) async {
    List<LatLng> snappedPoints = [];
    for (var point in waypoints) {
      try {
        final url =
            'https://roads.googleapis.com/v1/snapToRoads?path=${point['lat']},${point['lng']}&key=$apiKey';
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['snappedPoints'] != null) {
            final snapped = data['snappedPoints'][0]['location'];
            snappedPoints.add(LatLng(snapped['latitude'], snapped['longitude']));
          } else {
            print("Snap 실패, 원래 좌표 유지: ${point['lat']}, ${point['lng']}");
            snappedPoints.add(LatLng(point['lat'], point['lng']));
          }
        }
      } catch (e) {
        print("SnapToRoad 오류: $e");
      }
    }
    return snappedPoints;
  }

  List<Map<String, dynamic>> _transitDetails = []; // 대중교통 세부 정보 저장

  Future<void> getTransitRouteWithWaypoints() async {
    if (_startPoint == null || _endPoint == null) {
      print("출발지와 목적지를 설정해주세요.");
      return;
    }

    LatLng snappedStart = await snapToRoad(_startPoint!);
    LatLng snappedEnd = await snapToRoad(_endPoint!);

    // 경유지를 최적화된 순서로 정렬
    List<Map<String, dynamic>> filteredWaypoints = _scheduleList
        .where((place) =>
    !(place['lat'] == _startPoint!.latitude &&
        place['lng'] == _startPoint!.longitude) &&
        !(place['lat'] == _endPoint!.latitude &&
            place['lng'] == _endPoint!.longitude))
        .toList();

    List<LatLng> snappedWaypoints = await snapToRoadsForWaypoints(filteredWaypoints);

    // waypoints에 optimize:true 추가
    String waypoints = snappedWaypoints
        .map((point) => "${point.latitude},${point.longitude}")
        .join('|');

    String optimizedWaypoints =
    waypoints.isNotEmpty ? "&waypoints=optimize:true|$waypoints" : "";

    // Directions API 요청 URL
    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${snappedStart.latitude},${snappedStart.longitude}&destination=${snappedEnd.latitude},${snappedEnd.longitude}&mode=transit&key=$apiKey$optimizedWaypoints';

    print("API 요청 URL: $url");
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['status'] == 'OK') {
      print("경로 발견: 대중교통 모드");

      List<LatLng> coords = [];
      List<Map<String, dynamic>> transitDetails = []; // 세부 정보 저장

      for (var leg in data['routes'][0]['legs']) {
        for (var step in leg['steps']) {
          PolylinePoints polylinePoints = PolylinePoints();
          List<PointLatLng> decodedPoints =
          polylinePoints.decodePolyline(step['polyline']['points']);
          coords.addAll(
              decodedPoints.map((e) => LatLng(e.latitude, e.longitude)));

          if (step['travel_mode'] == 'TRANSIT') {
            var transit = step['transit_details'];
            transitDetails.add({
              'line': transit['line']['short_name'] != null
                  ? "${transit['line']['short_name']} (${transit['line']['name']})"
                  : transit['line']['name'] ?? "알 수 없는 노선",
              'departure_stop': transit['departure_stop']['name'] ?? "출발 정류장",
              'arrival_stop': transit['arrival_stop']['name'] ?? "도착 정류장",
              'duration': step['duration']['text'] ?? "시간 정보 없음",
              'vehicle': transit['line']['vehicle']['name'] ?? "알 수 없는 이동 수단",
            });
          }
        }
      }

      setState(() {
        _polylines.clear();
        _polylines.add(Polyline(
          polylineId: PolylineId("optimized_transit_route"),
          points: coords,
          color: Colors.blueAccent,
          width: 5,
        ));
        _transitDetails = transitDetails; // 세부 정보 저장
      });
    } else {
      print("경로를 찾을 수 없습니다: 상태 = ${data['status']}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('대중교통 경로를 찾을 수 없습니다.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }







  // Firestore에서 찜한 장소 불러오기
  void fetchFavoritePlaces() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    List<Map<String, dynamic>> places = [];
    final categories = [
      'favorite_restaurants',
      'favorite_landmarks',
      'favorite_accommodations'
    ];

    for (String category in categories) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection(category)
          .get();

      for (var doc in snapshot.docs) {
        places.add({
          'place_id': doc['place_id'],
          'lat': doc['latitude'],
          'lng': doc['longitude']
        });
      }
    }

    setState(() {
      _markers = places.map((place) {
        return Marker(
          markerId: MarkerId(place['place_id']),
          position: LatLng(place['lat'], place['lng']),
          onTap: () async {
            final details = await fetchPlaceDetails(place['place_id']);
            setState(() {
              _selectedPlace = details;
              _selectedMarkerPosition = LatLng(place['lat'], place['lng']);
            });
          },
        );
      }).toSet();
    });
  }

  // Google Places API로 장소 세부정보 불러오기
  Future<Map<String, dynamic>> fetchPlaceDetails(String placeId) async {
    final url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result'] ?? {};
      }
    } catch (e) {
      print('Error fetching place details: $e');
    }
    return {};
  }

  // 스케줄에 추가
  void addToSchedule(Map<String, dynamic> place) {
    setState(() {
      _scheduleList.add({
        'name': place['name'] ?? '알 수 없는 장소',
        'lat': place['geometry']['location']['lat'],
        'lng': place['geometry']['location']['lng']
      });
      _selectedPlace = null; // 인포창 닫기
    });

    print("추가된 장소: ${_scheduleList.last}"); // 로그로 확인
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${place['name'] ?? '알 수 없는 장소'}가 스케줄에 추가되었습니다.'),
        duration: Duration(seconds: 1), // 1초로 설정
      ),
    );
  }



  Widget _buildModeSelector() {
    return SizedBox.shrink(); // 빈 위젯으로 교체
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('스케줄 페이지')),
      body: Stack(
        children: [
          // Google Map 영역
          Column(
            children: [
              Expanded(
                flex: 2,
                child: Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: (controller) => _mapController = controller,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(widget.latitude, widget.longitude),
                        zoom: 12,
                      ),
                      markers: _markers,
                      polylines: _polylines,
                    ),
                    _buildCustomInfoWindow(), // 커스텀 인포창 추가
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey), // 상단과 하단 분리

              // 하단 영역
              Expanded(
                flex: 1,
                child: DefaultTabController(
                  length: 2, // 탭 개수 (스케줄, 대중교통)
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: Colors.blueAccent,
                        tabs: [
                          Tab(text: '스케줄'),
                          Tab(text: '대중교통 정보'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // 스케줄 리스트
                            Column(
                              children: [
                                // 최적화 동선 버튼
                                ElevatedButton(
                                  onPressed: getTransitRouteWithWaypoints,
                                  child: Text('최적화된 동선 표시'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _scheduleList.length,
                                    itemBuilder: (context, index) {
                                      final place = _scheduleList[index];
                                      return ListTile(
                                        leading: Icon(Icons.location_pin, color: Colors.blue),
                                        title: Text(place['name'] ?? '알 수 없는 장소'),
                                        subtitle: Text(
                                            '위도: ${place['lat']}, 경도: ${place['lng']}'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.play_arrow),
                                              onPressed: () {
                                                setState(() {
                                                  _startPoint = LatLng(place['lat'], place['lng']);
                                                });
                                                _showSnackBar('출발지가 설정되었습니다.');
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.flag),
                                              onPressed: () {
                                                setState(() {
                                                  _endPoint = LatLng(place['lat'], place['lng']);
                                                });
                                                _showSnackBar('목적지가 설정되었습니다.');
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            // 대중교통 정보
                            _transitDetails.isNotEmpty
                                ? ListView.builder(
                              itemCount: _transitDetails.length,
                              itemBuilder: (context, index) {
                                final detail = _transitDetails[index];
                                return Card(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  elevation: 2,
                                  child: ListTile(
                                    leading: Icon(Icons.directions_transit,
                                        color: Colors.green),
                                    title: Text(
                                        "${detail['line']} (${detail['vehicle']})"),
                                    subtitle: Text(
                                      "출발: ${detail['departure_stop']} → 도착: ${detail['arrival_stop']}\n소요 시간: ${detail['duration']}",
                                      style: TextStyle(height: 1.4),
                                    ),
                                  ),
                                );
                              },
                            )
                                : Center(child: Text("대중교통 경로가 없습니다.")),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// 스낵바를 표시하는 함수
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 1),
      ),
    );
  }


  // 커스텀 인포창 위젯
  Widget _buildCustomInfoWindow() {
    if (_selectedPlace == null || _selectedMarkerPosition == null)
      return SizedBox();

    Future<ScreenCoordinate> getMarkerScreenPosition() async {
      return await _mapController.getScreenCoordinate(_selectedMarkerPosition!);
    }

    return FutureBuilder<ScreenCoordinate>(
      future: getMarkerScreenPosition(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();

        final screenPosition = snapshot.data!;
        final left = screenPosition.x.toDouble() - 160; // 인포창 너비 절반 조정
        final top = screenPosition.y.toDouble() - 250; // 마커 위로 이동

        return Positioned(
          left: left,
          top: top,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(maxWidth: 320), // 최대 너비 설정
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          _selectedPlace!['name'] ?? '알 수 없는 장소',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            _selectedPlace = null;
                            _selectedMarkerPosition = null;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    _selectedPlace!['formatted_address'] ?? '주소 정보 없음',
                    style: TextStyle(fontSize: 13, height: 1.2), // 줄 간격 조정
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '평점: ${_selectedPlace!['rating'] ??
                        '등록된 평점 없음'}   전화번호: ${_selectedPlace!['formatted_phone_number'] ??
                        '없음'}',
                    style: TextStyle(fontSize: 13, height: 1.2),
                  ),
                  SizedBox(height: 8),
                  _selectedPlace!['photos'] != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${_selectedPlace!['photos'][0]['photo_reference']}&key=$apiKey',
                      width: 300, // 너비를 인포창에 맞춤
                      height: 160, // 사진 높이 설정
                      fit: BoxFit.cover,
                    ),
                  )
                      : Container(
                    height: 160,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: Icon(Icons.image_not_supported, size: 50),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius
                            .circular(8)),
                        padding: EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                      ),
                      onPressed: () => addToSchedule(_selectedPlace!),
                      child: Text('스케줄에 추가', style: TextStyle(color: Colors
                          .white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}