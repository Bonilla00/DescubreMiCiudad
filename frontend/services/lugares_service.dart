import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_model.dart';
import '../constants/api.dart';

class LugaresService {
  Future<List<Place>> getLugares({double? lat, double? lng, String? categoria}) async {
    String url = "${ApiConstants.apiBaseUrl}/lugares";
    Map<String, String> params = {};
    if (lat != null) params['lat'] = lat.toString();
    if (lng != null) params['lng'] = lng.toString();
    if (categoria != null && categoria != "Todos") params['categoria'] = categoria;

    if (params.isNotEmpty) {
      url += "?" + Uri(queryParameters: params).query;
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((item) => Place.fromJson(item)).toList();
    }
    return [];
  }

  Future<List<Place>> getCercanos({required double lat, required double lng}) async {
    try {
      print('DEBUG: Solicitando lugares cercanos a lat: $lat, lng: $lng');
      final response = await http.get(
        Uri.parse("${ApiConstants.apiBaseUrl}/lugares/cercanos?lat=$lat&lng=$lng"),
      ).timeout(const Duration(seconds: 10));
      
      print('DEBUG: Respuesta Backend: ${response.body}');
      
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        print('DEBUG: Lugares mapeados: ${data.length}');
        return data.map((item) => Place.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('DEBUG: Error en getCercanos: $e');
      return [];
    }
  }

  Future<List<Place>> getGoogleCercanos({required double lat, required double lng}) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.apiBaseUrl}/lugares/google-cercanos?lat=$lat&lng=$lng"),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map((item) => Place.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error en getGoogleCercanos: $e');
      return [];
    }
  }

  Future<bool> eliminarResena(int resenaId, String token) async {
    final response = await http.delete(
      Uri.parse("${ApiConstants.apiBaseUrl}/resenas/$resenaId"),
      headers: {"Authorization": "Bearer $token"},
    );
    return response.statusCode == 200;
  }

  Future<bool> editarResena(int resenaId, String comentario, int rating, String token) async {
    final response = await http.put(
      Uri.parse("${ApiConstants.apiBaseUrl}/resenas/$resenaId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
      body: jsonEncode({"comentario": comentario, "rating": rating}),
    );
    return response.statusCode == 200;
  }
}
