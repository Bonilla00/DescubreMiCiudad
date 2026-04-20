import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../services/lugares_service.dart';
import '../models/place_model.dart';
import 'login_screen.dart';
import 'place_detail_screen.dart';
import 'search_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _nombre;
  final AuthService _authService = AuthService();
  final LugaresService _lugaresService = LugaresService();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    final nombre = await _authService.getNombre();
    setState(() => _nombre = nombre);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Descubre Mi Ciudad', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A73E8),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _authService.logout();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          )
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeBody(nombre: _nombre, lugaresService: _lugaresService),
          const SearchScreen(),
          const MapScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF1A73E8),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
        ],
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  final String? nombre;
  final LugaresService lugaresService;

  const _HomeBody({this.nombre, required this.lugaresService});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Hola, ${nombre ?? "Invitado"}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: lugaresService.getLugares(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No hay lugares disponibles"));
              }

              final places = snapshot.data!.map((item) => Place.fromJson(item)).toList();

              return ListView.builder(
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final place = places[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: place.imagenUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[200]),
                          errorWidget: (context, url, error) => const Icon(Icons.image_not_supported),
                        ),
                      ),
                      title: Text(place.nombre),
                      subtitle: Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFF59E0B), size: 16),
                          Text(place.rating.toString()),
                        ],
                      ),
                      trailing: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(const Color(0xFF1A73E8)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PlaceDetailScreen(place: place)),
                          );
                        },
                        child: const Text("Ver Más", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
