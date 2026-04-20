import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../constants/api.dart';
import '../models/place_model.dart';

class FavoritosService {
  final AuthService _authService = AuthService();

  Future<List<Place>> getFavoritos() async {
    final token = await _authService.getToken();
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/favoritos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
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
    final token = await _authService.getToken();
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/favoritos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'lugar_id': lugarId}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['favorito'];
      }
    } catch (e) {
      print("Error toggleFavorito: $e");
    }
    return false;
  }

  Future<bool> checkFavorito(int lugarId) async {
    final token = await _authService.getToken();
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/favoritos/check/$lugarId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['esFavorito'];
      }
    } catch (e) {
      print("Error checkFavorito: $e");
    }
    return false;
  }
}
