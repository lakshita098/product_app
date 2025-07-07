import 'package:shared_preferences/shared_preferences.dart';

class SharedService {
  static const String _loginKey = "is_logged_in";

  /// Save login state
  static Future<void> login() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loginKey, true);
  }

  /// Check login state
  static Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loginKey) ?? false;
  }

  /// Clear login state
  static Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginKey);
  }
}
