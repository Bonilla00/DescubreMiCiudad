import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/place_model.dart';
import 'details_screen.dart';

class CercanosScreen extends StatefulWidget {
  const CercanosScreen({super.key});

  @override
  State<CercanosScreen> createState() => _CercanosScreenState();
}

class _CercanosScreenState extends State<CercanosScreen> {
  List<dynamic> _restaurantes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRestaurantes();
  }

  Future<void> _fetchRestaurantes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Obtener ubicación
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final url = "${ApiConstants.apiBaseUrl}/lugares?lat=${position.latitude}&lng=${position.longitude}";
      print("--- DEBUG HTTP ---");
      print("URL: $url");

      // 2. Petición HTTP
      final response = await http.get(Uri.parse(url));
      
      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print("TOTAL RESTAURANTES: ${data.length}");

        // 3. Guardar en estado con setState
        setState(() {
          _restaurantes = data;
          _isLoading = false;
        });
      } else {
        throw "Error del servidor: ${response.statusCode}";
      }
    } catch (e) {
      print("ERROR EN FLUTTER: $e");
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Restaurantes en Cali"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRestaurantes,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text("Error: $_errorMessage"))
              : _restaurantes.isEmpty
                  ? const Center(child: Text("No se encontraron restaurantes cercanos."))
                  : ListView.builder(
                      itemCount: _restaurantes.length,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (context, index) {
                        final r = _restaurantes[index];
                        
                        // Mapeo seguro de datos
                        final String nombre = r['nombre'] ?? 'Sin nombre';
                        final String categoria = r['categoria'] ?? 'Restaurante';
                        final double lat = (r['lat'] ?? 0.0).toDouble();
                        final double lng = (r['lng'] ?? 0.0).toDouble();
                        final String imagen = r['imagen_url'] ?? 'https://via.placeholder.com/150';

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imagen,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.restaurant),
                              ),
                            ),
                            title: Text(
                              nombre,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(categoria),
                                Text("Ubicación: $lat, $lng", style: const TextStyle(fontSize: 10)),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // Navegar a detalles usando el modelo
                              final place = Place.fromJson(r);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => DetailsScreen(place: place)),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
