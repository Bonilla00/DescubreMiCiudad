import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PersistenceService {
  static const String _favKey = 'local_favorites';
  static const String _reviewsKey = 'local_reviews';

  // --- Favoritos ---
  Future<List<int>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? favs = prefs.getStringList(_favKey);
    if (favs == null) return [];
    return favs.map((e) => int.parse(e)).toList();
  }

  Future<bool> isFavorite(int placeId) async {
    final favs = await getFavorites();
    return favs.contains(placeId);
  }

  Future<bool> toggleFavorite(int placeId) async {
    final prefs = await SharedPreferences.getInstance();
    List<int> favs = await getFavorites();
    bool isFav;
    if (favs.contains(placeId)) {
      favs.remove(placeId);
      isFav = false;
    } else {
      favs.add(placeId);
      isFav = true;
    }
    await prefs.setStringList(_favKey, favs.map((e) => e.toString()).toList());
    return isFav;
  }

  // --- Reseñas (Estrellas y Comentarios) ---
  Future<void> saveLocalReview(int placeId, String comment, double rating) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> reviews = await _getAllReviews();

    reviews[placeId.toString()] = {
      'comment': comment,
      'rating': rating,
      'date': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_reviewsKey, jsonEncode(reviews));
  }

  Future<Map<String, dynamic>?> getLocalReview(int placeId) async {
    Map<String, dynamic> reviews = await _getAllReviews();
    return reviews[placeId.toString()];
  }

  Future<Map<String, dynamic>> _getAllReviews() async {
    final prefs = await SharedPreferences.getInstance();
    final String? reviewsJson = prefs.getString(_reviewsKey);
    if (reviewsJson == null) return {};
    return jsonDecode(reviewsJson);
  }
}
