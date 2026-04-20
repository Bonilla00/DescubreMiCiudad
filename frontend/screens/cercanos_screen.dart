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
      print("1. Verificando permisos de ubicación...");
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      double lat = 3.4516; // Default Cali
      double lng = -76.5320; // Default Cali

      try {
        print("2. Intentando obtener ubicación GPS...");
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5), // Límite de 5 seg para no bloquear la app
        );
        lat = position.latitude;
        lng = position.longitude;
        print("GPS EXITOSO: $lat, $lng");
      } catch (e) {
        print("GPS FALLÓ (Usando Cali por defecto): $e");
      }

      final url = "${ApiConstants.apiBaseUrl}/lugares?lat=$lat&lng=$lng";
      print("3. Llamando al Backend: $url");

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      
      print("STATUS: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print("4. TOTAL RESTAURANTES RECIBIDOS: ${data.length}");

        setState(() {
          _restaurantes = data;
          _isLoading = false;
        });
      } else {
        throw "Servidor respondió con error ${response.statusCode}";
      }
    } catch (e) {
      print("ERROR CRÍTICO: $e");
      setState(() {
        _errorMessage = "No se pudo cargar la lista. Verifica tu conexión.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Restaurantes en Cali"),
        backgroundColor: Colors.orangeAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRestaurantes,
          )
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Buscando restaurantes cercanos..."),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchRestaurantes,
              child: _restaurantes.isEmpty
                  ? const Center(child: Text("No se encontraron restaurantes."))
                  : ListView.builder(
                      itemCount: _restaurantes.length,
                      padding: const EdgeInsets.all(12),
                      itemBuilder: (context, index) {
                        final r = _restaurantes[index];
                        final String nombre = r['nombre'] ?? 'Restaurante';
                        final String cat = r['categoria'] ?? 'Comida';
                        final String img = r['imagen_url'] ?? 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4';
                        
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 15),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(10),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                img,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.restaurant, size: 40),
                              ),
                            ),
                            title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Text(cat),
                            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.orange),
                            onTap: () {
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
            ),
    );
  }
}
