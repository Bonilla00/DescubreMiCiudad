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

  Future<void> _loadFavoritos() async {
    final list = await _favoritosService.getFavoritos();
    if (mounted) {
      setState(() {
        _favoritos = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorito(String id) async {
    final userId = await _favoritosService.getAuthService().getUserId();
    if (userId == null) return;

    await _favoritosService.toggleFavorito(id, Place(
      id: id,
      nombre: '',
      categoria: '',
      rating: 0,
      descripcion: '',
      imagenUrl: '',
      lat: 0,
      lng: 0,
    ));
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
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("No tienes favoritos aún", style: TextStyle(color: Colors.grey, fontSize: 18)),
                      SizedBox(height: 8),
                      Text("Explora lugares y guarda tus favoritos", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favoritos.length,
                  itemBuilder: (context, i) {
                    final place = _favoritos[i];
                    return Dismissible(
                      key: Key(place.id),
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
                              placeholder: (context, url) => Container(width: 80, height: 80, color: Colors.grey[200]),
                              errorWidget: (context, url, error) => Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.restaurant)),
                            ),
                          ),
                          title: Text(place.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(place.categoria),
                              if (place.rating > 0) Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(place.rating.toStringAsFixed(1)),
                                ],
                              ),
                            ],
                          ),
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
