import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/place_model.dart';
import 'auth_service.dart';

class LugaresService {
  final AuthService _authService = AuthService();

  // Helper para obtener headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Place>> getLugares({double? lat, double? lng}) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConstants.places))
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        
        return body.map((item) {
          return Place(
            id: item['id'],
            nombre: item['nombre'] ?? '',
            categoria: item['categoria'] ?? 'Restaurante',
            precio: item['precio'] ?? '\$',
            priceLevel: '',
            rating: double.tryParse(item['rating'].toString()) ?? 0.0,
            distancia: '',
            descripcion: item['descripcion'] ?? '',
            imagenUrl: item['imagen'] ?? 'https://via.placeholder.com/400', 
            lat: double.tryParse(item['latitud'].toString()) ?? 0.0,
            lng: double.tryParse(item['longitud'].toString()) ?? 0.0,
          );
        }).toList();
      }
    } catch (e) {
      print("Error getLugares: $e");
    }
    return [];
  }

  Future<List<Place>> getLugaresCercanos(double lat, double lng) async {
    // Requerimiento: Mostrar todos sin filtrar por distancia
    return await getLugares();
  }

  Future<List<Place>> getGoogleCercanos(double lat, double lng) async => [];

  Future<Map<String, dynamic>?> getLugarById(dynamic id) async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConstants.places}/$id'))
          .timeout(ApiConstants.timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error getLugarById: $e");
    }
    return null;
  }

  Future<bool> agregarResenaConRating(dynamic lugarId, String comentario, int rating, String token) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final response = await http.post(
        Uri.parse(ApiConstants.reviews),
        headers: headers,
        body: jsonEncode({
          'lugar_id': lugarId,
          'comentario': comentario,
          'rating': rating,
        }),
      ).timeout(ApiConstants.timeout);
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error agregarResena: $e");
      return false;
    }
  }
}
