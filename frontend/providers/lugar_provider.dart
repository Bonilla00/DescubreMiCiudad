import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import '../models/place_model.dart';
import '../constants/api.dart';

class LugarProvider with ChangeNotifier {
  List<Place> _lugares = [];
  bool _isLoading = false;

  List<Place> get lugares => _lugares;
  bool get isLoading => _isLoading;

  Future<void> fetchLugares({String? categoria, String? precio}) async {
    _isLoading = true;
    notifyListeners();

    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (_) {}

      String url = "${ApiConstants.apiBaseUrl}/lugares";
      Map<String, String> params = {};
      if (position != null) {
        params['lat'] = position.latitude.toString();
        params['lng'] = position.longitude.toString();
      }
      if (categoria != null && categoria != "Todos") {
        params['categoria'] = categoria;
      }

      if (params.isNotEmpty) {
        url += "?" + Uri(queryParameters: params).query;
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        _lugares = data.map((l) => Place.fromJson(l)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching places: $e");
    }

    if (precio != null && precio != "Todos") {
      _lugares = _lugares.where((l) => l.rangoPrecio == precio).toList();
    }

    _isLoading = false;
    notifyListeners();
  }
}
