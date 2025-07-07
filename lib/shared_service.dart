// ignore: unused_import
import 'package:shared_preferences/shared_preferences.dart';

class SharedService {
  static Future<void> saveLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', true);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('isLoggedIn');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }
}

class SharedPreferences {
  static Future getInstance() async {}
}
