import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/place_model.dart';
import '../models/resena_model.dart';
import 'auth_service.dart';

class LugaresService {
  final AuthService _authService = AuthService();

  // Expone el servicio para los logs en UI
  AuthService getAuthService() => _authService;

  // --- LUGARES ---
  Future<List<Place>> getLugares({double? lat, double? lng}) async {
    try {
      String url = ApiConstants.places;
      if (lat != null && lng != null) url += "?lat=$lat&lng=$lng";

      final response = await http.get(Uri.parse(url)).timeout(ApiConstants.timeout);
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => _mapearItem(item)).toList();
      }
    } catch (e) { print("Error API: $e"); }
    return [];
  }

  // --- RESEÑAS ---
  Future<List<Resena>> getResenas(String lugarId) async {
    try {
      final response = await http.get(Uri.parse("${ApiConstants.baseUrl}/api/resenas/$lugarId"));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((e) => Resena.fromJson(e)).toList();
      }
    } catch (e) { print("Error Reseñas: $e"); }
    return [];
  }

  // MÉTODO PRINCIPAL: Enviar reseña
  Future<bool> agregarResenaConRating(
    String lugarId,
    String comentario,
    int rating,
  ) async {
    try {
      final userId = await _authService.getUserId();
      final nombre = await _authService.getNombre();
      
      final url = Uri.parse("${ApiConstants.baseUrl}/api/resenas");
      final body = jsonEncode({
        'lugar_id': lugarId,
        'usuario_id': userId,
        'usuario_nombre': nombre,
        'comentario': comentario,
        'rating': rating,
      });

      debugPrint("🚀 ENVIANDO RESEÑA A: $url");
      debugPrint("📦 BODY RESEÑA: $body");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      debugPrint("📥 RESPUESTA RESEÑA STATUS: ${response.statusCode}");
      debugPrint("📥 RESPUESTA RESEÑA BODY: ${response.body}");

      return response.statusCode == 201;
    } catch (e) {
      debugPrint("❌ ERROR CRÍTICO agregarResena: $e");
      return false;
    }
  }

  // --- FAVORITOS ---
  Future<bool> esFavorito(String lugarId) async {
    try {
      final userId = await _authService.getUserId();
      debugPrint("🔍 VERIFICANDO FAVORITO - USER: $userId, LUGAR: $lugarId");
      if (userId == null) return false;

      final url = Uri.parse("${ApiConstants.baseUrl}/api/favoritos/$userId/$lugarId");
      final response = await http.get(url);

      debugPrint("📥 RESPUESTA ES_FAVORITO STATUS: ${response.statusCode}");
      debugPrint("📥 RESPUESTA ES_FAVORITO BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isFavorite'] ?? false;
      }
    } catch (e) {
      debugPrint("❌ ERROR esFavorito: $e");
    }
    return false;
  }

  Future<bool> toggleFavorito(String lugarId, bool yaEsFavorito) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        debugPrint("⚠️ ERROR: userId es NULL en toggleFavorito");
        return false;
      }

      final headers = {'Content-Type': 'application/json'};

      if (yaEsFavorito) {
        final url = Uri.parse("${ApiConstants.baseUrl}/api/favoritos/$userId/$lugarId");
        debugPrint("🗑️ ELIMINANDO FAVORITO EN: $url");
        final response = await http.delete(url, headers: headers);
        debugPrint("📥 RESPUESTA DELETE STATUS: ${response.statusCode}");
        return response.statusCode == 200;
      } else {
        final url = Uri.parse("${ApiConstants.baseUrl}/api/favoritos");
        final body = jsonEncode({'usuario_id': userId, 'lugar_id': lugarId});
        debugPrint("❤️ AGREGANDO FAVORITO A: $url");
        debugPrint("📦 BODY FAVORITO: $body");
        
        final response = await http.post(url, headers: headers, body: body)
            .timeout(const Duration(seconds: 10)); // ⏱️ TIEMPO LÍMITE

        debugPrint("📥 RESPUESTA POST STATUS: ${response.statusCode}");
        debugPrint("📥 RESPUESTA POST BODY: ${response.body}");
        return response.statusCode == 201 || response.statusCode == 200;
      }
    } catch (e) {
      debugPrint("❌ ERROR toggleFavorito: $e");
      return false;
    }
  }

  // --- HELPERS ---
  Place _mapearItem(Map<String, dynamic> item) {
    return Place(
      id: item['id']?.toString() ?? '',
      nombre: item['nombre'] ?? '',
      categoria: 'Restaurante',
      precio: item['precio'] ?? '\$\$',
      priceLevel: '',
      rating: double.tryParse(item['rating'].toString()) ?? 0.0,
      distancia: '',
      descripcion: item['descripcion'] ?? '',
      imagenUrl: item['imagen'] ?? '', 
      lat: double.tryParse(item['latitud'].toString()) ?? 0.0,
      lng: double.tryParse(item['longitud'].toString()) ?? 0.0,
    );
  }

  Future<List<Place>> getLugaresCercanos(double lat, double lng) => getLugares(lat: lat, lng: lng);
}
