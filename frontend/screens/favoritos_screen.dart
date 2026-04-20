import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/favoritos_service.dart';
import '../models/place_model.dart';
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

  Future<void> _eliminar(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    await _service.toggleFavorito(id, token);
    _cargarFavoritos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis Favoritos"), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _favoritos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  const Text("No tienes favoritos aún", style: TextStyle(color: Colors.grey)),
                  const Text("Agrega lugares tocando el corazón", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _favoritos.length,
              itemBuilder: (context, index) {
                final l = _favoritos[index];
                return Dismissible(
                  key: Key(l.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (dir) => _eliminar(l.id as int),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      leading: Image.network(l.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                      title: Text(l.nombre),
                      subtitle: Text("${l.categoria} • ${l.promedioCalificacion} ⭐"),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsScreen(place: l))),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
