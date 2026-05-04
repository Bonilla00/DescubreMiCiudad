import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place_model.dart';
import '../services/lugares_service.dart';
import '../services/auth_service.dart';
import 'place_detail_screen.dart';
import 'search_screen.dart';
import 'favoritos_screen.dart';
import 'perfil_screen.dart';
import 'cercanos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _nombre = "Cargando...";
  final LugaresService _lugaresService = LugaresService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    final nombre = await _authService.getNombre();
    setState(() => _nombre = nombre ?? "Usuario");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeBody(nombre: _nombre, lugaresService: _lugaresService),
          const SearchScreen(),
          const CercanosScreen(),
          const FavoritosScreen(),
          const PerfilScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF1A73E8),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
          BottomNavigationBarItem(icon: Icon(Icons.near_me), label: 'Cercanos'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _HomeBody extends StatefulWidget {
  final String nombre;
  final LugaresService lugaresService;
  const _HomeBody({required this.nombre, required this.lugaresService});
  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  String _selectedCat = "Todos";
  List<Place> _allPlaces = [];
  List<Place> _filteredPlaces = [];
  bool _isLoading = true;
  double? _userLat;
  double? _userLng;

  final List<String> _categorias = ["Todos", "Restaurante", "Cafés", "Discotecas"];

  @override
  void initState() {
    super.initState();
    _initUbicacionYFetch();
  }

  Future<void> _initUbicacionYFetch() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position pos = await Geolocator.getCurrentPosition();
        _userLat = pos.latitude;
        _userLng = pos.longitude;
      }
    } catch (e) {
      debugPrint("Error ubicacion: $e");
    }
    _fetch();
  }

  void _fetch() async {
    final list = await widget.lugaresService.getLugares(lat: _userLat, lng: _userLng);
    if (mounted) {
      setState(() {
        _allPlaces = list;
        _filteredPlaces = list;
        _isLoading = false;
      });
    }
  }

  void _filter(String cat) {
    setState(() {
      _selectedCat = cat;
      _filteredPlaces = cat == "Todos" ? _allPlaces : _allPlaces.where((p) => p.categoria == cat).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Hola, ${widget.nombre} 👋", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    if (_userLat != null) _buildLocationChip(),
                  ],
                ),
                const Text("¿Qué quieres explorar hoy?", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categorias.length,
              itemBuilder: (context, i) {
                bool isSel = _selectedCat == _categorias[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(_categorias[i]),
                    selected: isSel,
                    onSelected: (_) => _filter(_categorias[i]),
                    selectedColor: const Color(0xFF1A73E8),
                    labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredPlaces.length,
                    itemBuilder: (context, i) {
                      final p = _filteredPlaces[i];
                      return _buildPlaceCard(p);
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildLocationChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.my_location, size: 12, color: Color(0xFF1A73E8)),
          SizedBox(width: 4),
          Text("Ubicación activa", style: TextStyle(fontSize: 11, color: Color(0xFF1A73E8))),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(Place p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: p))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: CachedNetworkImage(
                imageUrl: p.imagenUrl,
                height: 180,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("${p.categoria} • ${p.precio}"),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(8)),
                        child: Row(children: [const Icon(Icons.star, color: Colors.amber, size: 16), Text(" ${p.rating}", style: const TextStyle(fontWeight: FontWeight.bold))]),
                      )
                    ],
                  ),
                  if (p.distanciaInfo != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 14, color: Color(0xFF1A73E8)),
                        Text(" ${p.distanciaInfo!.distanciaTexto}  ", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        const Text("·", style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 4),
                        Icon(Icons.directions_walk, size: 14, color: Colors.grey.shade600),
                        Text(" ${p.distanciaInfo!.caminando}  ", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        Icon(Icons.directions_car, size: 14, color: Colors.grey.shade600),
                        Text(" ${p.distanciaInfo!.carro}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
