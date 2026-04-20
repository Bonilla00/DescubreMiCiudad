import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import 'auth_service.dart';

class LugaresService {
  final AuthService _authService = AuthService();

  Future<List<dynamic>> getLugares() async {
    try {
      final response = await http.get(Uri.parse(apiLugares));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLugarById(int id) async {
    try {
      final response = await http.get(Uri.parse('$apiLugares/$id'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> buscarLugares({String? q, String? categoria, String? precio}) async {
    try {
      final queryParams = <String, String>{};
      if (q != null && q.isNotEmpty) queryParams['q'] = q;
      if (categoria != null && categoria.isNotEmpty) queryParams['categoria'] = categoria;
      if (precio != null && precio.isNotEmpty) queryParams['precio'] = precio;

      final uri = Uri.parse('$baseUrl/api/lugares/buscar').replace(queryParameters: queryParams);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> agregarResena(int lugarId, String comentario) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse(apiResenas),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'lugar_id': lugarId,
          'comentario': comentario,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
