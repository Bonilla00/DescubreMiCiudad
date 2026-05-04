import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/favoritos_service.dart';
import '../models/place_model.dart';
import '../widgets/restaurant_card.dart';
import 'details_screen.dart';

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  final _service = FavoritosService();
  List<Place> _favoritos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarFavoritos();
  }

  Future<void> _cargarFavoritos() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final res = await _service.getFavoritos(token);
    setState(() {
      _favoritos = res;
      _isLoading = false;
    });
  }

  Future<void> _refreshFavoritos() async {
    await _cargarFavoritos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Mis Favoritos',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF008A45),
                    ),
              ),
            ),

            // Contenido
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _favoritos.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _refreshFavoritos,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: _favoritos.length,
                            itemBuilder: (context, index) {
                              final place = _favoritos[index];
                              return Dismissible(
                                key: Key(place.id.toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                onDismissed: (dir) async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  final token = prefs.getString('token') ?? '';
                                  await _service.toggleFavorito(
                                      place.id as int, token);
                                  setState(() {
                                    _favoritos.removeAt(index);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${place.nombre} eliminado de favoritos'),
                                      action: SnackBarAction(
                                        label: 'Deshacer',
                                        onPressed: () async {
                                          await _service.toggleFavorito(
                                              place.id as int, token);
                                          _cargarFavoritos();
                                        },
                                      ),
                                    ),
                                  );
                                },
                                child: RestaurantCard(
                                  place: place,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DetailsScreen(place: place),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No tienes favoritos aún',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega lugares tocando el corazón en las tarjetas de restaurantes',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
