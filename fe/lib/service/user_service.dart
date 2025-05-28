import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api.dart';
Future<Map<String, String>?> fetchUserData(int mand) async {
  final String url = ApiConstants.nguoidungUrl;

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'maND': mand.toString(),
      },
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['status'] == 'success') {
      return {
        'HoVaTen': responseData['data']['hoTen'],
        'IMG': responseData['data']['IMG'],
      };
    } else {
      return null;
    }
  } catch (e) {
    print('Request failed: $e');
    return null;
  }
}
