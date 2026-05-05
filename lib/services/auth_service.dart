import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyLoggedIn = 'is_logged_in';
  static const String _keyEmail = 'user_email';
  static const String _keyNombre = 'user_nombre';
  static const String _keyUserId = 'user_id';

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  Future<Map<String, dynamic>> register(String nombre, String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = DateTime.now().millisecondsSinceEpoch;
      await prefs.setBool(_keyLoggedIn, true);
      await prefs.setString(_keyEmail, email);
      await prefs.setString(_keyNombre, nombre);
      await prefs.setInt(_keyUserId, userId);
      return {'success': true, 'userId': userId, 'nombre': nombre};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    final nombre = prefs.getString(_keyNombre) ?? email.split('@')[0];
    return {'success': true, 'nombre': nombre};
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
  }

  Future<String?> getNombre() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyNombre);
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  Future<String?> getToken() async => null;
}
