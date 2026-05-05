import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/place_model.dart';
import '../models/resena_model.dart';
import 'auth_service.dart';

class LugaresService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- LUGARES ---
  Future<List<Place>> getLugares({double? lat, double? lng}) async {
    try {
      String url = ApiConstants.places;
      if (lat != null && lng != null) url += "?lat=$lat&lng=$lng";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List body = jsonDecode(response.body);
        return body.map((item) => _mapearItem(item)).toList();
      }
    } catch (e) { print(e); }
    return [];
  }

  // --- FAVORITOS ---
  Future<List<String>> getFavoritos() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse("${ApiConstants.baseUrl}/favoritos"), headers: headers);
      if (response.statusCode == 200) {
        return List<String>.from(jsonDecode(response.body));
      }
    } catch (e) { print(e); }
    return [];
  }

  Future<void> toggleFavorito(String lugarId, bool isFav) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse("${ApiConstants.baseUrl}/favoritos/$lugarId");
      if (isFav) {
        await http.delete(url, headers: headers);
      } else {
        await http.post(url, headers: headers);
      }
    } catch (e) { print(e); }
  }

  // --- RESEÑAS & LIKES ---
  Future<List<Resena>> getResenas(String lugarId) async {
    try {
      final response = await http.get(Uri.parse("${ApiConstants.baseUrl}/resenas/$lugarId"));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((e) => Resena.fromJson(e)).toList();
      }
    } catch (e) { print(e); }
    return [];
  }

  Future<void> toggleLike(int resenaId, bool alreadyLiked) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse("${ApiConstants.baseUrl}/likes/$resenaId");
      if (alreadyLiked) {
        await http.delete(url, headers: headers);
      } else {
        await http.post(url, headers: headers);
      }
    } catch (e) { print(e); }
  }

  Future<bool> publicarResena(String lugarId, String comentario, int rating) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/api/resenas"),
        headers: headers,
        body: jsonEncode({'lugar_id': lugarId, 'comentario': comentario, 'rating': rating}),
      );
      return response.statusCode == 201;
    } catch (e) { return false; }
  }

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
