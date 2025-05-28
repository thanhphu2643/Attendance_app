import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:here_sdk/search.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:here_sdk/core.dart';

import '../api.dart';

class SetTargetPage extends StatefulWidget {
  @override
  _SetTargetPageState createState() => _SetTargetPageState();
}

class _SetTargetPageState extends State<SetTargetPage> {
  LatLng? markedLocation;
  final _searchController = TextEditingController();
  List<Suggestion> _suggestions = [];
  late SearchEngine _searchEngine;
  LatLng? selectedLocation;

  @override
  void initState() {
    super.initState();
    _initializeHERESDK();
    _searchController.addListener(() {
      _searchLocations(_searchController.text);
    });
  }

  Future<void> _initializeHERESDK() async {
    SdkContext.init(IsolateOrigin.main);
    _searchEngine = SearchEngine();
  }

  Future<void> _searchLocations(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    final searchOptions = SearchOptions();
    final geoCoordinates = GeoCoordinates(10.8231, 106.6297); // TP.HCM
    final queryArea = TextQueryArea.withCenter(geoCoordinates);

    _searchEngine.suggest(
      TextQuery.withArea(query, queryArea),
      searchOptions,
          (SearchError? error, List<Suggestion>? suggestions) {
        if (error == null && suggestions != null) {
          setState(() {
            _suggestions = suggestions;
          });
        }
      },
    );
  }

  void _onSuggestionSelected(Suggestion suggestion) {
    final place = suggestion.place;
    if (place != null && place.geoCoordinates != null) {
      setState(() {
        selectedLocation = LatLng(place.geoCoordinates!.latitude, place.geoCoordinates!.longitude);
        // Cập nhật thanh tìm kiếm với địa điểm đã chọn
        _searchController.text = suggestion.title; // Hiển thị tên địa điểm đã chọn trong thanh tìm kiếm
        _suggestions = []; // Xóa gợi ý sau khi chọn
      });
    }
  }

  Future<void> _markLocation() async {
    if (selectedLocation != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? maND = prefs.getInt('maND');

      if (maND != null) {
        try {
          // Gửi yêu cầu đến API để lấy maCongTy
          final response = await http.post(
            Uri.parse(ApiConstants.nguoidungUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'maND': maND}),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            int maCongTy = data['data']['maCongTy']; // Đảm bảo đường dẫn đúng

            // Kiểm tra xem maCongTy có giá trị không
            if (maCongTy != null) {
              // Gửi dữ liệu kinh độ, vĩ độ, maND, maCongTy đến API Laravel
              final locationResponse = await http.post(
                Uri.parse(ApiConstants.savelocationUrl),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'latitude': selectedLocation!.longitude.toString(), // Đổi lại cho đúng
                  'longitude': selectedLocation!.latitude.toString(), // Đổi lại cho đúng
                  'maND': maND,
                  'maCongTy': maCongTy,
                }),
              );

              // Kiểm tra phản hồi
              if (locationResponse.statusCode == 200) {
                // Xử lý thông báo thành công
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Location marked and saved successfully!')),
                );
              } else {
                // Xử lý lỗi khi không lưu được địa điểm
                print('Location Response Status: ${locationResponse.statusCode}');
                print('Location Response Body: ${locationResponse.body}');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to save location.')),
                );
              }
            } else {
              // Nếu maCongTy không hợp lệ
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Company ID is null or invalid.')),
              );
            }
          } else {
            // Xử lý lỗi khi không lấy được thông tin công ty
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to get company information.')),
            );
          }
        } catch (e) {
          // Xử lý ngoại lệ
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } else {
        // Nếu maND không tồn tại trong SharedPreferences
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ID not found.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 245, 245, 245),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 245, 245, 245),
        title: Row(
          children: [
            Icon(Icons.edit_location_outlined),
            SizedBox(width: 8),    // Khoảng cách giữa icon và chữ
            Text(
              'Cập nhật tọa độ',
              style: TextStyle(
                fontWeight: FontWeight.bold, // Chữ đậm
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        color: Color.fromARGB(255, 245, 245, 245), // Màu nền
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Location',
                  prefixIcon: Icon(Icons.search), // Biểu tượng tìm kiếm
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white, // Màu nền của ô tìm kiếm
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    title: Text(suggestion.title),
                    onTap: () => _onSuggestionSelected(suggestion),
                  );
                },
              ),
            ),
            if (selectedLocation != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _markLocation,
                  child: Text('Chọn làm địa điểm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFA726), // Màu nền nút
                    foregroundColor: Colors.white, // Màu chữ nút
                    padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0), // Kéo dài chữ
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
