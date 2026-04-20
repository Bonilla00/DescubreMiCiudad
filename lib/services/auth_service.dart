import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api.dart';

class AuthService {
  Future<Map<String, dynamic>> register(String nombre, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(apiRegister),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'userId': data['userId']};
      } else {
        print("Error Server Registro: ${response.body}"); // Log para depurar
        return {'success': false, 'error': data['error'] ?? 'Error al registrar'};
      }
    } catch (e) {
      print("Error Conexión Registro: $e"); // Log para depurar
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(apiLogin),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('nombre', data['usuario']['nombre']);
        return {'success': true, 'nombre': data['usuario']['nombre']};
      } else {
        print("Error Server Login: ${response.body}"); // Log para depurar
        return {'success': false, 'error': data['error'] ?? 'Credenciales incorrectas'};
      }
    } catch (e) {
      print("Error Conexión Login: $e"); // Log para depurar
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('nombre');
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

  Future<Map<String, dynamic>> getPerfil() async {
    final token = await getToken();
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/usuarios/perfil'),
        headers: {'Authorization': 'Bearer $token'},
      );
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
        Uri.parse('$apiBaseUrl/api/usuarios/perfil'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(datos),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Error de conexión: $e'};
    }
  }
}
