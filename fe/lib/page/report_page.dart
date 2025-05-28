import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api.dart';
import '../service/shared_preferences.dart';

class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  DateTime _currentDate = DateTime.now();
  DateTime? _startDate;
  DateTime? _endDate;
  PageController _pageController = PageController(initialPage: 0);

  // Variables to store attendance statistics
  double _totalAttendance = 0;
  int _lateInCount = 0;
  int _earlyOutCount = 0;

  String? _checkInTime;
  String? _checkOutTime;
  List<Map<String, dynamic>> _lateAttendanceDetails = [];
  List<Map<String, dynamic>> _earlyOutDetails = [];
  final List<String> _dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  void initState() {
    super.initState();
    _fetchAttendanceStatistics();
    _fetchAttendanceDetails();
  }

  Future<void> _fetchAttendanceStatistics() async {
    try {
      int? maND = await getMaNDFromSharedPreferences();
      if (maND == null) {
        print('User ID not found in SharedPreferences');
        return;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.thongKeCongUrl),
        body: jsonEncode({'maND': maND}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _totalAttendance = (data['tongCong'] as num).toDouble() ?? 0;
          _lateInCount = data['soNgayDiTre'] ?? 0;
          _earlyOutCount = data['soNgayVeSom'] ?? 0;
        });
      } else {
        throw Exception('Failed to load attendance statistics');
      }
    } catch (error) {
      print(error);
    }
  }

  Future<void> _fetchAttendanceDetails() async {
    try {
      int? maND = await getMaNDFromSharedPreferences();
      if (maND == null) {
        print('User ID not found in SharedPreferences');
        return;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.chiTietChamCongUrl),
        body: jsonEncode({'maND': maND}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _checkInTime = data['data']['gioCheckin'] ?? 'Chưa có dữ liệu';
          _checkOutTime = data['data']['gioCheckout'] ?? 'Chưa có dữ liệu';
        });
      } else {
        throw Exception('Failed to load attendance details');
      }
    } catch (error) {
      print(error);
    }
  }

  Future<void> reloadData() async {
    await _fetchAttendanceStatistics();
    await _fetchAttendanceDetails();
  }

  void _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      // Call method to fetch attendance data by date range
      await _fetchAttendanceDataByDateRange(_startDate!, _endDate!);
    }
  }

  Future<void> _fetchAttendanceDataByDateRange(DateTime start, DateTime end) async {
    try {
      int? maND = await getMaNDFromSharedPreferences();
      if (maND == null) {
        print('User ID not found in SharedPreferences');
        return;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.baoCaoTheoThoiGianUrl),
        body: jsonEncode({
          'maND': maND,
          'startDate': DateFormat('yyyy-MM-dd').format(start),
          'endDate': DateFormat('yyyy-MM-dd').format(end),
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // Lưu trữ chi tiết điểm danh muộn và về sớm
          _lateAttendanceDetails = List<Map<String, dynamic>>.from(data['chiTietDiTre']);
          _earlyOutDetails = List<Map<String, dynamic>>.from(data['chiTietVeSom']);

          // Cập nhật các giá trị thống kê
          _totalAttendance = (data['tongCong'] as num).toDouble() ?? 0;
          _lateInCount = data['soNgayDiTre'] ?? 0; // Cập nhật số ngày đi trễ
          _earlyOutCount = data['soNgayVeSom'] ?? 0; // Cập nhật số ngày về sớm
        });
      } else {
        throw Exception('Failed to load attendance report');
      }
    } catch (error) {
      print(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F5F5),
        title: Text('Báo cáo', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: reloadData,
            icon: Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => _selectDateRange(context),
            icon: Icon(Icons.calendar_today),
          ),
        ],
      ),
      backgroundColor: Color(0xFFF5F5F5),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Đã chấm công', _totalAttendance, Colors.green),
                _buildStatItem('Đi trễ', _lateInCount.toDouble(), Colors.red),
                _buildStatItem('Về sớm', _earlyOutCount.toDouble(), Colors.yellow),
              ],
            ),
          ),
          Divider(),
          SizedBox(
            height: 80,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentDate = DateTime.now().add(Duration(days: (index - 0) * 7));
                });
              },
              itemBuilder: (context, index) {
                DateTime startOfWeek = _currentDate.subtract(Duration(days: _currentDate.weekday - 1)).add(Duration(days: (index - 0) * 7));
                return _buildWeekView(startOfWeek);
              },
            ),
          ),
          Divider(),
          Expanded(
            child: ListView(
              children: [
                _buildAttendanceDetail(
                  'Ca làm việc',
                  _checkInTime ?? 'Chưa có dữ liệu',
                  _checkOutTime ?? 'Chưa có dữ liệu',
                ),
                // Hiển thị chi tiết điểm danh muộn
                if (_lateAttendanceDetails.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Chi tiết đi trễ:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ..._lateAttendanceDetails.map((item) => _buildLateAttendanceDetail(item)),
                // Hiển thị chi tiết về sớm
                if (_earlyOutDetails.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Chi tiết về sớm:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ..._earlyOutDetails.map((item) => _buildEarlyOutDetail(item)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLateAttendanceDetail(Map<String, dynamic> detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ngày: ${detail['ngay']}', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Check In: ${detail['gioCheckin']}', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEarlyOutDetail(Map<String, dynamic> detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ngày: ${detail['ngay']}', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Check Out: ${detail['gioCheckout']}', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, double count, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildWeekView(DateTime startOfWeek) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        DateTime currentDate = startOfWeek.add(Duration(days: index));
        bool isToday = DateUtils.isSameDay(currentDate, DateTime.now());
        return Column(
          mainAxisSize: MainAxisSize.min, // Giảm kích thước cột
          children: [
            Text(
              _dayNames[index],
              style: TextStyle(fontWeight: FontWeight.bold, color: isToday ? Colors.blue : Colors.black, fontSize: 14), // Giảm kích thước văn bản
            ),
            SizedBox(height: 4), // Giảm khoảng cách
            Container(
              padding: EdgeInsets.all(4.0), // Giảm padding
              decoration: BoxDecoration(
                color: isToday ? Colors.blue.withOpacity(0.3) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                DateFormat('dd/MM').format(currentDate), // Định dạng ngày và tháng
                style: TextStyle(
                  fontSize: 16, // Giảm kích thước văn bản
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? Colors.blue : Colors.black,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildAttendanceDetail(String title, String checkIn, String checkOut) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Check In: $checkIn'),
            Text('Check Out: $checkOut'),
          ],
        ),
      ),
    );
  }
}
