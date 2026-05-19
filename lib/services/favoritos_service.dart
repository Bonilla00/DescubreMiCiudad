import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/place_model.dart';
import 'auth_service.dart';

class FavoritosService {
  final AuthService _authService = AuthService();

  AuthService getAuthService() => _authService;

  Future<bool> esFavorito(String lugarId) async {
    final userId = await _authService.getUserId();
    if (userId == null) return false;

    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/api/favoritos/$userId/$lugarId"),
      ).timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isFavorite'] ?? false;
      }
    } catch (e) {
      debugPrint("Error esFavorito: $e");
    }
    return false;
  }

  Future<bool> toggleFavorito(String lugarId, Place place) async {
    final userId = await _authService.getUserId();
    if (userId == null) return false;

    try {
      final isFav = await esFavorito(lugarId);

      if (isFav) {
        final response = await http.delete(
          Uri.parse("${ApiConstants.baseUrl}/api/favoritos/$userId/$lugarId"),
        );
        return response.statusCode == 200;
      } else {
        final response = await http.post(
          Uri.parse("${ApiConstants.baseUrl}/api/favoritos"),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'usuario_id': userId,
            'lugar_id': lugarId,
            'nombre': place.nombre,
            'imagen': place.imagenUrl,
            'categoria': place.categoria,
            'latitud': place.lat,
            'longitud': place.lng,
          }),
        );
        return response.statusCode == 201 || response.statusCode == 200;
      }
    } catch (e) {
      debugPrint("Error toggleFavorito: $e");
      return false;
    }
  }

  Future<List<Place>> getFavoritos() async {
    final userId = await _authService.getUserId();
    if (userId == null) {
      debugPrint("getFavoritos: userId es null");
      return [];
    }

    debugPrint("getFavoritos: userId=$userId");

    try {
      final url = "${ApiConstants.baseUrl}/api/favoritos/user/$userId";
      debugPrint("getFavoritos: URL=$url");
      
      final response = await http.get(Uri.parse(url)).timeout(ApiConstants.timeout);

      debugPrint("getFavoritos: status=${response.statusCode}");
      debugPrint("getFavoritos: body=${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        debugPrint("getFavoritos: items=${body.length}");
        return body.map((item) => Place.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint("Error getFavoritos: $e");
    }
    return [];
  }
}
