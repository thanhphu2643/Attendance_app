import 'package:shared_preferences/shared_preferences.dart';

Future<int?> getMaNDFromSharedPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getInt('maND');
}
Future<bool?> getIsFirstLoginFromSharedPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isFirstLogin');
}
