import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/lugar_provider.dart';
import '../providers/auth_provider.dart';
import 'details_screen.dart';
import 'cercanos_screen.dart';
import 'search_screen.dart';
import 'favoritos_screen.dart';
import 'perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const HomeContent(),
    const SearchScreen(),
    const CercanosScreen(),
    const FavoritosScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Cercanos'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String _selectedCategory = "Todos";
  String _selectedPrice = "Todos";
  bool _ubicacionActiva = false;
  String? _userNombre;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LugarProvider>(context, listen: false).fetchLugares();
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userNombre = prefs.getString('nombre');
    });
  }

  Future<void> _checkLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    setState(() {
      _ubicacionActiva = (permission == LocationPermission.always || permission == LocationPermission.whileInUse);
    });
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Filtrar por Categoría", style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: ["Todos", "Cafés", "Discotecas", "Restaurantes"].map((cat) {
                      return FilterChip(
                        label: Text(cat),
                        selected: _selectedCategory == cat,
                        onSelected: (selected) {
                          setState(() => _selectedCategory = cat);
                          setModalState(() => _selectedCategory = cat);
                          Provider.of<LugarProvider>(context, listen: false)
                              .fetchLugares(categoria: _selectedCategory, precio: _selectedPrice);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text("Filtrar por Precio", style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: ["Todos", "Económico", "Moderado", "Caro"].map((p) {
                      return FilterChip(
                        label: Text(p),
                        selected: _selectedPrice == p,
                        onSelected: (selected) {
                          setState(() => _selectedPrice = p);
                          setModalState(() => _selectedPrice = p);
                          Provider.of<LugarProvider>(context, listen: false)
                              .fetchLugares(categoria: _selectedCategory, precio: _selectedPrice);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lugarProvider = Provider.of<LugarProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Descubre Mi Ciudad"),
        actions: [
          IconButton(onPressed: _showFilters, icon: const Icon(Icons.filter_list)),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilScreen())).then((_) => _loadUserData()),
            icon: const Icon(Icons.account_circle),
          ),
          IconButton(
            onPressed: () async {
              authProvider.logout();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) Navigator.pushReplacementNamed(context, '/');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: lugarProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                              backgroundColor: Color(0xFFEF3340), child: Icon(Icons.person, color: Colors.white)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text("Hola, ${_userNombre ?? authProvider.userName ?? 'Visitante'}",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          if (_ubicacionActiva)
                            const Chip(
                              label: Text("Ubicación activa", style: TextStyle(fontSize: 10, color: Colors.white)),
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: lugarProvider.lugares.length,
                    itemBuilder: (context, index) {
                      final lugar = lugarProvider.lugares[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DetailsScreen(place: lugar)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.network(
                                lugar.imageUrl,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 150,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported, size: 50),
                                ),
                              ),
                              ListTile(
                                title: Text(lugar.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("${lugar.categoria} • ${lugar.rangoPrecio}"),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 20),
                                    Text(lugar.promedioCalificacion.toString()),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
