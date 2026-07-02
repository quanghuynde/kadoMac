import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _userEmailKey = 'userEmail';
  static const String _userPasswordKey = 'userPassword';

  Future<bool> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString(_userEmailKey);
    final storedPassword = prefs.getString(_userPasswordKey);

    if (email == storedEmail && password == storedPassword) {
      await prefs.setBool(_isLoggedInKey, true);
      return true;
    }
    // Default admin for testing
    if (email == 'admin@gmail.com' && password == '123456') {
      await prefs.setBool(_isLoggedInKey, true);
      return true;
    }
    return false;
  }

  Future<void> register(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userPasswordKey, password);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }
}
