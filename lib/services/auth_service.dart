import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api.dart';

class AuthService {
  Future<Map<String, dynamic>> register(String nombre, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'email': email,
          'password': password,
        }),
      ).timeout(ApiConstants.timeout);

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'userId': data['userId']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Error al registrar'};
      }
    } on TimeoutException {
      return {'success': false, 'error': 'El servidor tarda mucho en responder. Reintenta.'};
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(ApiConstants.timeout);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('nombre', data['usuario']['nombre']);
        await prefs.setInt('userId', data['usuario']['id']); // Guardamos userId como int
        return {'success': true, 'nombre': data['usuario']['nombre']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Credenciales incorrectas'};
      }
    } on TimeoutException {
      return {'success': false, 'error': 'El servidor tarda mucho en responder.'};
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  
  Future<String?> getNombre() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nombre');
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  Future<Map<String, dynamic>> getPerfil() async {
    final token = await getToken();
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.profile),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(ApiConstants.timeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'Error al obtener perfil'};
    } catch (e) {
      return {'error': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> actualizarPerfil(Map<String, dynamic> datos) async {
    final token = await getToken();
    try {
      final response = await http.put(
        Uri.parse(ApiConstants.profileUpdate),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(datos),
      ).timeout(ApiConstants.timeout);
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Error de conexión: $e'};
    }
  }
}
