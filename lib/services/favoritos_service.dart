import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/place_model.dart';
import 'auth_service.dart';

class FavoritosService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Place>> getFavoritos() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConstants.favorites),
        headers: headers,
      ).timeout(ApiConstants.timeout);
      
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Place.fromJson(item)).toList();
      }
    } catch (e) {
      print("Error getFavoritos: $e");
    }
    return [];
  }

  Future<bool> toggleFavorito(int lugarId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiConstants.favorites),
        headers: headers,
        body: jsonEncode({'lugar_id': lugarId}),
      ).timeout(ApiConstants.timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['favorito'] ?? false;
      }
    } catch (e) {
      print("Error toggleFavorito: $e");
    }
    return false;
  }

  Future<bool> checkFavorito(int lugarId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.favorites}/check/$lugarId'),
        headers: headers,
      ).timeout(ApiConstants.timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['esFavorito'] ?? false;
      }
    } catch (e) {
      print("Error checkFavorito: $e");
    }
    return false;
  }
}
