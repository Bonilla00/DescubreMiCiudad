import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/favoritos_service.dart';
import '../models/place_model.dart';
import 'place_detail_screen.dart';

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  final FavoritosService _favoritosService = FavoritosService();
  List<Place> _favoritos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoritos();
  }

  void _loadFavoritos() async {
    final list = await _favoritosService.getFavoritos();
    if (mounted) {
      setState(() {
        _favoritos = list;
        _isLoading = false;
      });
    }
  }

  void _removeFavorito(int id) async {
    await _favoritosService.toggleFavorito(id);
    _loadFavoritos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Favoritos", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A73E8),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoritos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("No tienes favoritos aún", style: TextStyle(color: Colors.grey, fontSize: 18)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favoritos.length,
                  itemBuilder: (context, i) {
                    final place = _favoritos[i];
                    return Dismissible(
                      key: Key(place.id.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (dir) => _removeFavorito(place.id),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: place.imagenUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(place.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(place.categoria),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)),
                          ).then((_) => _loadFavoritos()),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
