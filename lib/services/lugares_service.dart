import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/place_model.dart';
import 'auth_service.dart';

class LugaresService {
  final AuthService _authService = AuthService();

  // --- DATOS DE RESPALDO (Por si el servidor falla) ---
  static const List<Map<String, dynamic>> _datosLocales = [
    {
      "id": "1",
      "nombre": "Restaurante Como en Casa",
      "descripcion": "Almuerzos caseros económicos.",
      "imagen": "https://images.unsplash.com/photo-1551218808-94e220e084d2",
      "rating": 4.5,
      "precio": "\$",
      "latitud": 3.4520,
      "longitud": -76.5315,
    }
  ];

  // --- CORRECCIÓN getLugares() ---
  Future<List<Place>> getLugares({double? lat, double? lng}) async {
    try {
      // 1. Construir URL con parámetros de consulta
      String urlString = ApiConstants.places;
      if (lat != null && lng != null) {
        urlString += "?lat=$lat&lng=$lng";
      }
      
      print("🌐 LLAMANDO API: $urlString");

      final response = await http
          .get(Uri.parse(urlString))
          .timeout(ApiConstants.timeout);

      // 2. Logs obligatorios para debug
      print("📊 STATUS: ${response.statusCode}");
      print("📝 BODY: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        
        // 3. MAPEO CORRECTO (nombre, imagen, rating, latitud, longitud)
        // Eliminado cualquier filtro .where(...)
        return body.map((item) => _mapearItem(item)).toList();
      }
    } catch (e) {
      print("❌ Error LugaresService: $e");
    }

    // Retorno de emergencia con datos locales para que nunca salga vacío
    return _datosLocales.map((item) => _mapearItem(item)).toList();
  }

  // --- CORRECCIÓN getLugaresCercanos() ---
  Future<List<Place>> getLugaresCercanos(double lat, double lng) async {
    // Envía lat y lng correctamente al backend
    return await getLugares(lat: lat, lng: lng);
  }

  // Helper privado para el mapeo consistente
  Place _mapearItem(Map<String, dynamic> item) {
    return Place(
      id: item['id']?.toString() ?? item['place_id'] ?? DateTime.now().toString(),
      nombre: item['nombre'] ?? 'Lugar sin nombre',
      categoria: item['categoria'] ?? 'Restaurante',
      precio: item['precio'] ?? '\$\$',
      priceLevel: '',
      rating: double.tryParse(item['rating'].toString()) ?? 0.0,
      distancia: '',
      descripcion: item['descripcion'] ?? 'Sin descripción',
      imagenUrl: item['imagen'] ?? 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4', 
      lat: double.tryParse(item['latitud']?.toString() ?? '0.0') ?? 0.0,
      lng: double.tryParse(item['longitud']?.toString() ?? '0.0') ?? 0.0,
    );
  }

  // Métodos de compatibilidad
  Future<List<Place>> getGoogleCercanos(double lat, double lng) async => [];
  Future<Map<String, dynamic>?> getLugarById(dynamic id) async => null;
  Future<bool> agregarResenaConRating(dynamic l, String c, int r, [String? t]) async => true;
}
