import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/place_model.dart';

class LugaresService {
  Future<List<Place>> getLugares({double? lat, double? lng}) async {
    try {
      // Coordenadas por defecto (Cali, CO) si no se proveen, para evitar errores de cálculo en el servidor
      final queryLat = lat ?? 3.4516;
      final queryLng = lng ?? -76.5320;
      
      final url = '${ApiConstants.places}?lat=$queryLat&lng=$queryLng';

      final response = await http.get(Uri.parse(url)).timeout(ApiConstants.timeout);
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Place.fromJson(item)).toList();
      }
    } catch (e) {
      print("Error getLugares: $e");
    }
    return [];
  }

  Future<List<Place>> getLugaresCercanos(double lat, double lng) async {
    try {
      final url = '${ApiConstants.places}/cercanos?lat=$lat&lng=$lng';
      final response = await http.get(Uri.parse(url)).timeout(ApiConstants.timeout);
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Place.fromJson(item)).toList();
      }
    } catch (e) {
      print("Error getLugaresCercanos: $e");
    }
    return [];
  }

  Future<List<Place>> getGoogleCercanos(double lat, double lng) async {
    try {
      final url = '${ApiConstants.places}/google-cercanos?lat=$lat&lng=$lng';
      final response = await http.get(Uri.parse(url)).timeout(ApiConstants.timeout);
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Place.fromJson(item)).toList();
      }
    } catch (e) {
      print("Error getGoogleCercanos: $e");
    }
    return [];
  }

  Future<List<Place>> buscarLugares({String? q, double? lat, double? lng}) async {
    try {
      String url = '${ApiConstants.places}/buscar';
      List<String> params = [];
      if (q != null) params.add('q=$q');
      if (lat != null && lng != null) {
        params.add('lat=$lat');
        params.add('lng=$lng');
      }
      if (params.isNotEmpty) {
        url += '?' + params.join('&');
      }
      final response = await http.get(Uri.parse(url)).timeout(ApiConstants.timeout);
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Place.fromJson(item)).toList();
      }
    } catch (e) {
      print("Error buscarLugares: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>?> getLugarById(int id) async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.places}/$id')).timeout(ApiConstants.timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error getLugarById: $e");
    }
    return null;
  }

  Future<bool> agregarResenaConRating(int lugarId, String comentario, int rating, String token) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.reviews),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'lugar_id': lugarId,
          'comentario': comentario,
          'rating': rating,
        }),
      ).timeout(ApiConstants.timeout);
      return response.statusCode == 201;
    } catch (e) {
      print("Error agregarResena: $e");
      return false;
    }
  }

  Future<bool> editarResena(int resenaId, String comentario, int rating, String token) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.reviews}/$resenaId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'comentario': comentario,
          'rating': rating,
        }),
      ).timeout(ApiConstants.timeout);
      return response.statusCode == 200;
    } catch (e) {
      print("Error editarResena: $e");
      return false;
    }
  }

  Future<bool> eliminarResena(int resenaId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.reviews}/$resenaId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConstants.timeout);
      return response.statusCode == 200;
    } catch (e) {
      print("Error eliminarResena: $e");
      return false;
    }
  }
}
