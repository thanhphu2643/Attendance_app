  import 'dart:async';
  import 'dart:convert';
  import 'package:checkin/page/report_page.dart';
  import 'package:flutter/material.dart';
  import 'package:here_sdk/core.dart';
  import 'package:here_sdk/core.errors.dart';
  import '../service/shared_preferences.dart';
  import '../service/user_service.dart';
  import 'package:here_sdk/core.engine.dart';
  import 'package:here_sdk/mapview.dart';
  import 'package:latlong2/latlong.dart';
  import 'package:permission_handler/permission_handler.dart';
  import 'package:geolocator/geolocator.dart';
  import '../api.dart';
  import 'face_recognition_screen.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:http/http.dart' as http;

  class AttendancePage extends StatefulWidget {
    final LatLng? markedLocation;
    AttendancePage({this.markedLocation});

    @override
    _AttendancePageState createState() => _AttendancePageState();
  }

  class _AttendancePageState extends State<AttendancePage> {
    String? _hoVaTen;
    String? _imgUrl;
    LatLng? userLocation;
    LatLng? markedLocation;
    HereMapController? _hereMapController;
    StreamSubscription<Position>? _positionStreamSubscription;
    LocationIndicator? _locationIndicator;

    MapMarker? _currentMarker;
    MapPolygon? _currentCircle;
    String _address = "Chưa xác định";
    @override
      void initState() {
        super.initState();
        _getUserInfo();
        markedLocation = widget.markedLocation ;
        _initializeHERESDK();
        _requestLocationPermission();
      }

    Future<void> _fetchLocation(int maCongTy) async {
      try {
        // Gửi yêu cầu đến API để lấy tọa độ
        final response = await http.post(
          Uri.parse(ApiConstants.getlocationUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'maCongTy': maCongTy}), // Sử dụng maCongTy
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success']) {
            // Lấy tọa độ từ phản hồi
            final location = data['data'];
            double latitude = double.parse(location['viDo']);
            double longitude = double.parse(location['kinhDo']);

            print('Latitude: $latitude');
            print('Longitude: $longitude');
            // Cập nhật markedLocation
            setState(() {
              markedLocation = LatLng(latitude, longitude);
            });
          } else {
            print('Không tìm thấy vị trí hoạt động');
          }
        } else {
          print('Lỗi khi lấy vị trí: ${response.body}');
        }
      } catch (e) {
        print('Lỗi khi gọi API: $e');
      }
    }


    Future<void> _getUserInfo() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? maND = prefs.getInt('maND'); // Lấy maND từ SharedPreferences

      if (maND != null) {
        final response = await http.post(
          Uri.parse(ApiConstants.nguoidungUrl), // Sử dụng ApiConstants
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'maND': maND}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // Kiểm tra xem dữ liệu có hợp lệ không
          if (data['data'] != null) {
            setState(() {
              _hoVaTen = data['data']['hoTen'] ?? 'Chưa có thông tin';
              _imgUrl = data['data']['IMG'] != null && data['data']['IMG'].isNotEmpty
                  ? '${ApiConstants.storageUrl}/${data['data']['IMG']}'
                  : 'assets/img/avatar.png';
            });

            // Gọi _fetchLocation với maCongTy từ phản hồi
            int maCongTy = data['data']['maCongTy'] ?? 0; // Lấy maCongTy từ dữ liệu
            if (maCongTy > 0) {
              await _fetchLocation(maCongTy);
            } else {
              print('Không tìm thấy maCongTy trong dữ liệu người dùng');
            }
          } else {
            setState(() {
              _hoVaTen = 'Không tìm thấy thông tin người dùng';
            });
          }
        } else {
          // Xử lý lỗi từ API
          print('Lỗi: ${response.body}');
          setState(() {
            _hoVaTen = 'Không tìm thấy thông tin người dùng';
          });
        }
      } else {
        // Nếu không có maND trong SharedPreferences
        setState(() {
          _hoVaTen = 'Không tìm thấy thông tin người dùng';
        });
      }
    }



    Future<void> _initializeHERESDK() async {
      SdkContext.init(IsolateOrigin.main);

      String accessKeyId = "WPLvW1VeKtyLiw_5w_Ljfw";
      String accessKeySecret = "I9NTR8O8jyV4Nlr6VN-0nD9QRUu5oKhx6xVSDXwbuc_yC0u44-W1fUXtppk0Nzm51XZ4uBSzJ95D8huAwZN8uQ";
      SDKOptions sdkOptions = SDKOptions.withAccessKeySecret(
          accessKeyId, accessKeySecret);

      try {
        await SDKNativeEngine.makeSharedInstance(sdkOptions);
        setState(() {}); // Update UI when SDK is ready
      } on InstantiationException {
        throw Exception("Failed to initialize the HERE SDK.");
      }
    }

    Future<void> _requestLocationPermission() async {
      final status = await Permission.locationWhenInUse.request();

      if (status.isGranted) {
        _startTrackingLocation();
      } else if (status.isDenied) {
        _showPermissionDeniedDialog();
      } else if (status.isPermanentlyDenied) {
        _showPermissionPermanentlyDeniedDialog();
      }
    }

    void _startTrackingLocation() {
      _positionStreamSubscription =
          Geolocator.getPositionStream().listen((Position position) {
            setState(() {
              userLocation = LatLng(position.latitude, position.longitude);
            });
            if (_hereMapController != null) {
              _updateMapLocation();
            }
          });
    }


    @override
    void dispose() {
      _positionStreamSubscription?.cancel();
      super.dispose();
    }

    void _updateMapLocation() {
      if (userLocation != null && _hereMapController != null) {
        const double distanceToEarthInMeters = 8000;
        MapMeasure mapMeasureZoom =
        MapMeasure(MapMeasureKind.distance, distanceToEarthInMeters);

        _hereMapController?.camera.lookAtPointWithMeasure(
            GeoCoordinates(userLocation!.latitude, userLocation!.longitude),
            mapMeasureZoom);

        _hereMapController?.mapScene
            .loadSceneForMapScheme(MapScheme.normalDay, (MapError? error) {
          if (error != null) {
            print('Map scene not loaded. MapError: ${error.toString()}');
          }
        });

        _updateLocationIndicator(
            GeoCoordinates(userLocation!.latitude, userLocation!.longitude),
            LocationIndicatorIndicatorStyle.navigation);

        if (markedLocation != null) {
          _addMarkerAtLocation(markedLocation!);
          _addCircleToMap(markedLocation!, 100);
        }
      }
    }

    void _addMarkerAtLocation(LatLng location) {
      if (_hereMapController != null) {
        final geoCoordinates =
        GeoCoordinates(location.latitude, location.longitude);

        try {
          // Nếu đã có marker hiện tại, xóa nó đi
          if (_currentMarker != null) {
            _hereMapController!.mapScene.removeMapMarker(_currentMarker!);
          }

          // Tạo marker mới
          final mapImage = MapImage.withFilePathAndWidthAndHeight('assets/img/point.png', 60, 60);
          _currentMarker = MapMarker(geoCoordinates, mapImage);

          // Thêm marker mới vào bản đồ
          _hereMapController!.mapScene.addMapMarker(_currentMarker!);
        } catch (e) {
          print("Error adding marker: $e");
        }
      } else {
        print("HereMapController is null");
      }
    }

    void _updateLocationIndicator(GeoCoordinates geoCoordinates,
        LocationIndicatorIndicatorStyle indicatorStyle) {
      if (_hereMapController != null) {
        if (_locationIndicator == null) {
          _locationIndicator = LocationIndicator();
          _locationIndicator!.locationIndicatorStyle =
              LocationIndicatorIndicatorStyle.pedestrian;
          _locationIndicator!.enable(_hereMapController!);
        }

        Location location = Location.withCoordinates(geoCoordinates);
        location.time = DateTime.now();
        location.bearingInDegrees = _getRandom(0, 360).toDouble();

        _locationIndicator!.updateLocation(location);
      }
    }

    void _addCircleToMap(LatLng center, double radiusInMeters) {
      if (_hereMapController != null) {
        // Xóa vòng tròn cũ nếu có
        if (_currentCircle != null) {
          _hereMapController!.mapScene.removeMapPolygon(_currentCircle!);
        }

        final geoCircle = GeoCircle(
            GeoCoordinates(center.latitude, center.longitude),
            radiusInMeters
        );
        final geoPolygon = GeoPolygon.withGeoCircle(geoCircle);
        final fillColor = Color.fromARGB(160, 0, 144, 138); // Màu bán trong suốt
        _currentCircle = MapPolygon(geoPolygon, fillColor);

        try {
          _hereMapController!.mapScene.addMapPolygon(_currentCircle!);
          print("Circle added to map at ${center.latitude}, ${center.longitude} with radius $radiusInMeters meters.");
        } catch (e) {
          print("Error adding circle to map: $e");
        }
      } else {
        print("HereMapController is null.");
      }
    }

    void _showPermissionDeniedDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Permission Denied'),
            content: Text(
                'App needs location access to function properly. Please grant permission in settings.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }

    void _showPermissionPermanentlyDeniedDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Permission Denied Permanently'),
            content: Text(
                'App needs location access to function properly. Please grant permission in app settings.'),
            actions: [
              TextButton(
                onPressed: () {
                  openAppSettings();
                },
                child: Text('Settings'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
            ],
          );
        },
      );
    }

    Widget _buildFooterButton(
        BuildContext context, IconData icon, String label, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30),
            SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 14)),
          ],
        ),
      );
    }

    int _getRandom(int min, int max) {
      return (min +
          (max - min) * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000)
          .toInt();
    }

    bool _isWithinRadius(
        LatLng point1, LatLng point2, double radiusInMeters) {
      final distance = Geolocator.distanceBetween(
        point1.latitude,
        point1.longitude,
        point2.latitude,
        point2.longitude,
      );
      return distance <= radiusInMeters;
    }

    @override
    Widget build(BuildContext context) {
      final canClockIn = userLocation != null &&
          markedLocation != null &&
          _isWithinRadius(userLocation!, markedLocation!, 100);
      return Scaffold(
        body: Container(
          color: Color.fromARGB(255, 245, 245, 245), // Màu xám nhạt cho nền ngoài
          child: Column(
            children: [
              // Header with user avatar and icons
              Padding(
                padding: const EdgeInsets.only(top: 40.0, left: 20.0, right: 20.0),
                child: Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: _imgUrl != null && _imgUrl!.isNotEmpty && _imgUrl!.startsWith('http')
                                ? NetworkImage(_imgUrl!) // Sử dụng NetworkImage cho URL
                                : AssetImage('assets/img/avatar.png') as ImageProvider,

                          ),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Xin chào',
                                style: TextStyle(fontSize: 14, color:  Colors.black),
                              ),
                              Text(
                                _hoVaTen ?? '...',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.notifications),
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
              // Location and map section wrapped together
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8), // Bo góc ít
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Location info
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Địa điểm:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                               "Chưa xác định",
                              style: TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Thời gian chấm công: ${TimeOfDay.now().format(context)}',
                              style: TextStyle(fontSize: 14, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      // Map section
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                        child: SizedBox(
                          height: 450, // Tăng chiều cao của bản đồ
                          child: HereMap(
                            onMapCreated: _onMapCreated,
                          ),
                        ),
                      ),
                      SizedBox(height: 10), // Khoảng cách giữa map và chú thích
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Center(
                          child: canClockIn
                              ? SizedBox.shrink() // Nếu nằm trong vị trí chấm công, không hiển thị gì
                              : Text(
                            '(Bạn cần nằm trong vị trí chấm công)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red, // Màu chữ đỏ
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (canClockIn)  // Điều kiện hiển thị nút "Chấm công"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FaceRecognitionApp()),
                      );
                    },
                    icon: Icon(Icons.access_time, color: Colors.white),
                    label: Text(
                      'Chấm công',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFFA726),
                      padding: EdgeInsets.symmetric(horizontal: 34, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // Bo góc nhiều hơn cho nút
                      ),
                      elevation: 5,
                    ),
                  ),
                ),
              SizedBox(height: 16),
            ],
          ),
        ),
      );

    }
      void _onMapCreated(HereMapController hereMapController) {
      _hereMapController = hereMapController;

      if (userLocation != null) {
        _updateMapLocation();
      }

      if (markedLocation != null) {
        _addMarkerAtLocation(markedLocation!);
        _addCircleToMap(markedLocation!, 100); // Add 100m radius circle
      }
    }
  }
