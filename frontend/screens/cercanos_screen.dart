import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/lugares_service.dart';
import '../models/place_model.dart';
import 'details_screen.dart'; // Aunque el usuario dijo que los modelos cambiaron, detalles_screen usará el modelo original por ahora si no lo ajusto.

class CercanosScreen extends StatefulWidget {
  const CercanosScreen({super.key});

  @override
  State<CercanosScreen> createState() => _CercanosScreenState();
}

class _CercanosScreenState extends State<CercanosScreen> {
  final LugaresService _service = LugaresService();
  List<Place> _lugares = [];
  bool _isLoading = true;
  String _filter = "Todos"; // Todos, App, Real

  @override
  void initState() {
    super.initState();
    _loadCercanos();
  }

  Future<void> _loadCercanos() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // 1. Verificar si el GPS está encendido
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'El GPS está desactivado. Por favor, actívalo.';
      }

      // 2. Verificar y pedir permisos
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permisos de ubicación denegados.';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Permisos de ubicación denegados permanentemente.';
      }

      // 3. Obtener ubicación con alta precisión
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('DEBUG: Ubicación obtenida -> ${position.latitude}, ${position.longitude}');
      
      // 4. Llamar al backend con coordenadas reales
      final appResults = await _service.getCercanos(lat: position.latitude, lng: position.longitude);
      
      // Intentar obtener de Google si la API Key está configurada
      List<Place> googleResults = [];
      try {
        googleResults = await _service.getGoogleCercanos(lat: position.latitude, lng: position.longitude);
      } catch (e) {
        print('DEBUG: Error opcional Google Places: $e');
      }
      
      List<Place> allPlaces = [...appResults, ...googleResults];
      print('DEBUG: Total lugares encontrados: ${allPlaces.length}');

      setState(() {
        _lugares = allPlaces;
        _isLoading = false;
      });
    } catch (e) {
      print('ERROR CRÍTICO: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  List<Place> get _filteredLugares {
    if (_filter == "App") return _lugares.where((l) => !l.esGooglePlace).toList();
    if (_filter == "Real") return _lugares.where((l) => l.esGooglePlace).toList();
    return _lugares;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lugares Cercanos"),
        actions: [
          IconButton(onPressed: _loadCercanos, icon: const Icon(Icons.refresh))
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: ["Todos", "App", "Real"].map((f) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(f),
                  selected: _filter == f,
                  onSelected: (val) => setState(() => _filter = f),
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _filteredLugares.length,
                  itemBuilder: (context, index) {
                    final l = _filteredLugares[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(l.imageUrl == 'GOOGLE_IMAGE' ? 'https://via.placeholder.com/150' : l.imageUrl),
                      ),
                      title: Text(l.nombre),
                      subtitle: Text(l.distanciaInfo != null 
                        ? "${l.distanciaInfo!.distanciaKm.toStringAsFixed(1)} km • ${l.distanciaInfo!.tiempoCarroMin} min 🚗" 
                        : l.categoria),
                      trailing: l.esGooglePlace 
                        ? const Badge(label: Text("Google"), backgroundColor: Colors.blue)
                        : const Badge(label: Text("App"), backgroundColor: Colors.green),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DetailsScreen(place: l)),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
