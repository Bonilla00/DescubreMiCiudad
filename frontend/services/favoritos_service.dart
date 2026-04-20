import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/place_model.dart';

class FavoritosService {
  Future<List<Place>> getFavoritos(String token) async {
    final response = await http.get(
      Uri.parse("${ApiConstants.apiBaseUrl}/favoritos"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((item) => Place.fromJson(item)).toList();
    }
    return [];
  }

  Future<bool> toggleFavorito(int lugarId, String token) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.apiBaseUrl}/favoritos/toggle"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"lugar_id": lugarId}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['favorito']; // true si se agregó, false si se quitó
    }
    return false;
  }

  Future<bool> checkFavorito(int lugarId, String token) async {
    final response = await http.get(
      Uri.parse("${ApiConstants.apiBaseUrl}/favoritos/check/$lugarId"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['esFavorito'];
    }
    return false;
  }
}
