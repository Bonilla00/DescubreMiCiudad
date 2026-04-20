import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api.dart';

class AuthService {
  Future<Map<String, dynamic>> register(String nombre, String email, String password) async {
    try {
      print('DEBUG: Intentando registro en ${ApiConstants.register}');
      final body = {
        'nombre': nombre,
        'email': email,
        'password': password,
      };
      print('DEBUG: Request Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(ApiConstants.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(ApiConstants.timeout);

      print('DEBUG: Status Code: ${response.statusCode}');
      print('DEBUG: Response Body: ${response.body}');

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'userId': data['userId']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Error al registrar'};
      }
    } on TimeoutException {
      print('DEBUG: Timeout en registro');
      return {'success': false, 'error': 'El servidor tarda mucho en responder.'};
    } catch (e) {
      print('DEBUG: Error de conexión: $e');
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('DEBUG: Intentando login en ${ApiConstants.login}');
      final body = {
        'email': email,
        'password': password,
      };
      print('DEBUG: Request Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(ApiConstants.timeout);

      print('DEBUG: Status Code: ${response.statusCode}');
      print('DEBUG: Response Body: ${response.body}');

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('nombre', data['usuario']['nombre']);
        
        final rawId = data['usuario']['id'];
        await prefs.setString('userId', rawId.toString());

        return {'success': true, 'nombre': data['usuario']['nombre']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Credenciales incorrectas'};
      }
    } on TimeoutException {
      print('DEBUG: Timeout en login');
      return {'success': false, 'error': 'El servidor tarda mucho en responder.'};
    } catch (e) {
      print('DEBUG: Error de conexión: $e');
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

  Future<Map<String, dynamic>> getPerfil(String token) async {
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

  Future<Map<String, dynamic>> actualizarPerfil({
    required String token,
    String? nombre,
    String? email,
    String? passwordActual,
    String? passwordNueva,
    String? fotoUrl,
  }) async {
    try {
      Map<String, dynamic> body = {};
      if (nombre != null) body['nombre'] = nombre;
      if (email != null) body['email'] = email;
      if (passwordActual != null) body['password_actual'] = passwordActual;
      if (passwordNueva != null) body['password_nueva'] = passwordNueva;
      if (fotoUrl != null) body['foto_url'] = fotoUrl;

      final response = await http.put(
        Uri.parse(ApiConstants.profileUpdate),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(ApiConstants.timeout);
      
      final data = jsonDecode(response.body);
      return {
        "success": response.statusCode == 200,
        "message": data['message'] ?? data['error'] ?? "Error desconocido",
        "usuario": data['usuario'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
