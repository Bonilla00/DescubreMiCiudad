import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userName;
  String? _userId;
  String? _token;

  bool get isAuthenticated => _isAuthenticated;
  String? get userName => _userName;
  String? get userId => _userId;
  String? get token => _token;

  AuthProvider() {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userId = prefs.getString('userId');
    _userName = prefs.getString('nombre');
    _isAuthenticated = _token != null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.login),
            headers: {"Content-Type": "application/json"},
            body: json.encode({"email": email, "password": password}),
          )
          .timeout(ApiConstants.timeout);

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        _userId = data['usuario']['id'].toString();
        _userName = data['usuario']['nombre'];
        _isAuthenticated = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('userId', _userId!);
        await prefs.setString('nombre', _userName!);

        notifyListeners();
        return {"success": true};
      } else {
        return {
          "success": false,
          "message": data['error'] ?? "Credenciales incorrectas"
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }

  Future<Map<String, dynamic>> register(
      String nombre, String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.register),
            headers: {"Content-Type": "application/json"},
            body: json.encode({
              "nombre": nombre.trim(),
              "email": email.trim().toLowerCase(),
              "password": password.trim()
            }),
          )
          .timeout(ApiConstants.timeout);

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          "success": true,
          "message": "Usuario creado exitosamente. Ya puedes iniciar sesión."
        };
      } else {
        // El backend devuelve { error: "mensaje" }, convertir a { message: "mensaje" }
        return {
          "success": false,
          "message": data['error'] ?? "Error al registrar. Intenta de nuevo."
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Error de conexión: Verifica tu conexión a internet"
      };
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _userName = null;
    _userId = null;
    _token = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }
}
