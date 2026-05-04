import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/place_model.dart';
import '../services/lugares_service.dart';
import 'place_detail_screen.dart';

class CercanosScreen extends StatefulWidget {
  const CercanosScreen({super.key});

  @override
  State<CercanosScreen> createState() => _CercanosScreenState();
}

class _CercanosScreenState extends State<CercanosScreen> {
  final LugaresService _lugaresService = LugaresService();
  List<Place> _allPlaces = [];
  List<Place> _filteredPlaces = [];
  bool _isLoading = true;
  String _currentFilter = 'Todos';
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getLocationAndPlaces();
  }

  Future<void> _getLocationAndPlaces() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError();
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition();
      final lat = _currentPosition!.latitude;
      final lng = _currentPosition!.longitude;

      final resultados = await Future.wait([
        _lugaresService.getLugaresCercanos(lat, lng),
        _lugaresService.getGoogleCercanos(lat, lng),
      ]);

      _allPlaces = [...resultados[0], ...resultados[1]];
      _allPlaces.sort((a, b) => (a.distanciaInfo?.distanciaKm ?? 0).compareTo(b.distanciaInfo?.distanciaKm ?? 0));
      
      _applyFilter(_currentFilter);
    } catch (e) {
      print("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLocationError() {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _currentPosition = null;
      });
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _currentFilter = filter;
      if (filter == 'Todos') {
        _filteredPlaces = _allPlaces;
      } else if (filter == 'En la app') {
        _filteredPlaces = _allPlaces.where((p) => !p.esGoogle).toList();
      } else {
        _filteredPlaces = _allPlaces.where((p) => p.esGoogle).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lugares Cercanos", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A73E8),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _getLocationAndPlaces,
          )
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Obteniendo tu ubicación..."),
                ],
              ),
            )
          : _currentPosition == null
              ? _buildNoLocation()
              : Column(
                  children: [
                    _buildFilterTabs(),
                    Expanded(
                      child: _filteredPlaces.isEmpty
                          ? const Center(child: Text("No hay lugares cercanos"))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredPlaces.length,
                              itemBuilder: (context, index) => _buildPlaceCard(_filteredPlaces[index]),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildNoLocation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("Activa la ubicación para continuar", style: TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Geolocator.openAppSettings(),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8)),
            child: const Text("Abrir configuración", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ['Todos', 'En la app', 'Lugares reales'].map((filter) {
          bool isActive = _currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => _applyFilter(filter),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF1A73E8) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.black,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlaceCard(Place place) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: CachedNetworkImage(
              imageUrl: place.imagenUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[200]),
              errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(place.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (place.esGoogle ? Colors.green : Colors.blue).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        place.esGoogle ? "Real" : "App",
                        style: TextStyle(color: place.esGoogle ? Colors.green : Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Text(place.categoria, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(" ${place.rating}  ", style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (place.distanciaInfo != null) ...[
                      const Icon(Icons.place, size: 14, color: Color(0xFF1A73E8)),
                      Text(" ${place.distanciaInfo!.distanciaTexto}  ", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ],
                ),
                if (place.distanciaInfo != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.directions_walk, size: 14, color: Colors.grey[600]),
                      Text(" ${place.distanciaInfo!.caminando}  ", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      Icon(Icons.directions_car, size: 14, color: Colors.grey[600]),
                      Text(" ${place.distanciaInfo!.carro}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (place.esGoogle) {
                        _openInMaps(place.lat, place.lng);
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: place.esGoogle ? Colors.green : const Color(0xFF1A73E8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      place.esGoogle ? "Ver en Maps" : "Ver Más",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openInMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
