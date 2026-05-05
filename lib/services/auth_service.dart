import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../constants/api.dart';

class AuthService {
  static const String _keyToken = 'jwt_token';
  static const String _keyUser = 'user_data';
  static const String _keyEmail = 'user_email';
  static const String _keyUserId = 'user_id'; // Nueva clave para el ID

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        
        await prefs.setString(_keyToken, data['token']);
        await prefs.setString(_keyUser, jsonEncode(data['user']));
        await prefs.setString(_keyEmail, email);
        
        // 🔥 GUARDAR userId PARA STATS
        await prefs.setInt(_keyUserId, data['user']['id']);
        
        return {'success': true};
      }
      return {'success': false, 'error': 'Credenciales inválidas'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> register(String nombre, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nombre': nombre, 'email': email, 'password': password}),
      );
      if (response.statusCode == 201) return {'success': true};
      return {'success': false, 'error': 'Error en registro'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<String?> getNombre() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_keyUser);
    if (userData != null) {
      return jsonDecode(userData)['nombre'];
    }
    return null;
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  Future<String?> getAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_keyUser);
    if (userData != null) {
      return jsonDecode(userData)['avatar'];
    }
    return null;
  }

  // MÉTODO AGREGADO: Obtener userId
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  // 🔥 NUEVO MÉTODO: Actualizar datos locales
  Future<void> updateLocalUserData(String nombre, String email, String? avatar) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Actualizar email individual
    await prefs.setString(_keyEmail, email);
    
    // Actualizar nombre y avatar dentro del JSON user_data
    final userDataString = prefs.getString(_keyUser);
    if (userDataString != null) {
      final Map<String, dynamic> userData = jsonDecode(userDataString);
      userData['nombre'] = nombre;
      if (avatar != null) {
        userData['avatar'] = avatar;
      }
      await prefs.setString(_keyUser, jsonEncode(userData));
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyUserId);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
