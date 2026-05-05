import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/place_model.dart';
import 'auth_service.dart';

class FavoritosService {
  final AuthService _authService = AuthService();

  // --- OBTENER TODOS LOS FAVORITOS ---
  Future<List<Place>> getFavoritos() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return [];

      // El backend necesita un endpoint para listar favoritos del usuario
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/api/favoritos/user/$userId"),
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

  // --- ALTERNAR FAVORITO ---
  Future<bool> toggleFavorito(String lugarId, {bool? actualmenteEsFavorito, Place? place}) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return false;

      bool eliminar = actualmenteEsFavorito ?? await checkFavorito(lugarId);

      if (eliminar) {
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
            'nombre': place?.nombre,
            'imagen': place?.imagenUrl,
            'categoria': place?.categoria,
          }),
        );
        return response.statusCode == 201 || response.statusCode == 200;
      }
    } catch (e) {
      print("Error toggleFavorito: $e");
      return false;
    }
  }

  // --- VERIFICAR ESTADO ---
  Future<bool> checkFavorito(String lugarId) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return false;

      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/api/favoritos/$userId/$lugarId"),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isFavorite'] ?? false;
      }
    } catch (e) {
      print("Error checkFavorito: $e");
    }
    return false;
  }
}
