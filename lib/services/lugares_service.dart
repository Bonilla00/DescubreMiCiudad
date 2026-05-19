import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/place_model.dart';
import '../models/resena_model.dart';
import 'auth_service.dart';

class LugaresService {
  final AuthService _authService = AuthService();

  Future<List<Place>> getLugares({double? lat, double? lng}) async {
    try {
      String url = ApiConstants.places;
      if (lat != null && lng != null) url += "?lat=$lat&lng=$lng";

      final response = await http.get(Uri.parse(url)).timeout(ApiConstants.timeout);
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Place.fromJson(item)).toList();
      }
    } catch (e) { debugPrint("Error API Lugares: $e"); }
    return [];
  }

  Future<List<Resena>> getResenas(String lugarId) async {
    try {
      final url = Uri.parse("${ApiConstants.baseUrl}/api/resenas/$lugarId");
      final response = await http.get(url).timeout(ApiConstants.timeout);
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((e) => Resena.fromJson(e)).toList();
      }
    } catch (e) { debugPrint("Error obtener Reseñas: $e"); }
    return [];
  }

  Future<List<Resena>> getResenasUsuario(String userId) async {
    try {
      final url = Uri.parse("${ApiConstants.baseUrl}/api/resenas/usuario/$userId");
      final response = await http.get(url).timeout(ApiConstants.timeout);
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((e) => Resena.fromJson(e)).toList();
      }
    } catch (e) { debugPrint("Error obtener Reseñas Usuario: $e"); }
    return [];
  }

  Future<bool> agregarResena(String lugarId, String lugarNombre, String comentario, int rating) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return false;

      final url = Uri.parse("${ApiConstants.baseUrl}/api/resenas");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usuario_id': userId,
          'lugar_id': lugarId,
          'lugar_nombre': lugarNombre,
          'comentario': comentario,
          'rating': rating,
        }),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint("Error agregarResena: $e");
      return false;
    }
  }
}
