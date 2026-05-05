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
    } catch (e) { debugPrint("Error API Lugares: $e"); }
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
    } catch (e) { debugPrint("Error obtener Reseñas: $e"); }
    return [];
  }

  Future<bool> agregarResenaConRating(String lugarId, String comentario, int rating) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return false;

      final url = Uri.parse("${ApiConstants.baseUrl}/api/resenas");
      final body = jsonEncode({
        'usuario_id': userId,
        'lugar_id': lugarId,
        'comentario': comentario,
        'rating': rating,
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      debugPrint("POST RESEÑA - Status: ${response.statusCode}");
      if (response.statusCode != 201) debugPrint("Error Body: ${response.body}");

      return response.statusCode == 201;
    } catch (e) {
      debugPrint("Error agregarResena: $e");
      return false;
    }
  }

  // --- FAVORITOS ---
  Future<bool> esFavorito(String lugarId) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return false;

      final url = Uri.parse("${ApiConstants.baseUrl}/api/favoritos/$userId/$lugarId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isFavorite'] ?? false;
      }
    } catch (e) { debugPrint("Error verificar favorito: $e"); }
    return false;
  }

  Future<bool> toggleFavorito(Place place, bool yaEsFavorito) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return false;

      if (yaEsFavorito) {
        final url = Uri.parse("${ApiConstants.baseUrl}/api/favoritos/$userId/${place.id}");
        final response = await http.delete(url);
        return response.statusCode == 200;
      } else {
        final url = Uri.parse("${ApiConstants.baseUrl}/api/favoritos");
        final body = jsonEncode({
          'usuario_id': userId,
          'lugar_id': place.id,
          'nombre': place.nombre,
          'imagen': place.imagenUrl,
          'categoria': place.categoria,
        });
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        );
        return response.statusCode == 201 || response.statusCode == 200;
      }
    } catch (e) {
      debugPrint("Error toggleFavorito: $e");
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
}
