import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/place_model.dart';
import '../constants/api.dart';
import '../services/lugares_service.dart';
import '../services/favoritos_service.dart';

class DetailsScreen extends StatefulWidget {
  final Place place;

  const DetailsScreen({super.key, required this.place});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final _lugaresService = LugaresService();
  final _favoritosService = FavoritosService();
  bool _esFavorito = false;
  int? _myUserId;
  List<dynamic> _resenas = [];
  bool _isLoadingResenas = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    final userIdStr = prefs.getString('userId');
    _myUserId = userIdStr != null ? int.tryParse(userIdStr) : null;
    final token = prefs.getString('token') ?? '';
    
    _checkFavorito(token);
    _cargarDetalles();
  }

  Future<void> _checkFavorito(String token) async {
    if (token.isEmpty || widget.place.esGooglePlace) return;
    final res = await _favoritosService.checkFavorito(widget.place.id as int, token);
    setState(() => _esFavorito = res);
  }

  Future<void> _toggleFavorito() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Inicia sesión para usar favoritos")));
      return;
    }
    
    final nuevoEstado = await _favoritosService.toggleFavorito(widget.place.id as int, token);
    setState(() => _esFavorito = nuevoEstado);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(nuevoEstado ? "Agregado a favoritos" : "Eliminado de favoritos"))
    );
  }

  Future<void> _cargarDetalles() async {
    try {
      final response = await http.get(Uri.parse("${ApiConstants.apiBaseUrl}/lugares/${widget.place.id}"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _resenas = data['resenas'] ?? [];
          _isLoadingResenas = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingResenas = false);
    }
  }

  Future<void> _openMap() async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${widget.place.latitud},${widget.place.longitud}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _showEditResena(dynamic resena) {
    final commentController = TextEditingController(text: resena['comentario']);
    double rating = (resena['rating'] ?? 5).toDouble();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Editar Reseña", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: commentController, decoration: const InputDecoration(labelText: "Comentario")),
            const SizedBox(height: 10),
            Row(
              children: List.generate(5, (i) => IconButton(
                icon: Icon(Icons.star, color: i < rating ? Colors.amber : Colors.grey),
                onPressed: () => rating = i + 1.0,
              )),
            ),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('token') ?? '';
                await _lugaresService.editarResena(resena['id'], commentController.text, rating.toInt(), token);
                Navigator.pop(ctx);
                _cargarDetalles();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reseña actualizada"), backgroundColor: Colors.green));
              },
              child: const Text("Guardar"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmEliminar(int id) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar reseña"),
        content: const Text("¿Seguro que deseas eliminar esta reseña?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
          TextButton(onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('token') ?? '';
            await _lugaresService.eliminarResena(id, token);
            Navigator.pop(ctx);
            _cargarDetalles();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reseña eliminada"), backgroundColor: Colors.green));
          }, child: const Text("ELIMINAR", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.place;
    return Scaffold(
      appBar: AppBar(
        title: Text(p.nombre),
        actions: [
          if (!p.esGooglePlace)
            IconButton(
              icon: Icon(_esFavorito ? Icons.favorite : Icons.favorite_border, color: _esFavorito ? Colors.red : null),
              onPressed: _toggleFavorito,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(p.imageUrl, height: 250, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey, height: 250, child: const Icon(Icons.image, size: 100))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p.categoria, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      Text(p.rangoPrecio, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(p.descripcion, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      Text(" ${p.promedioCalificacion} (${p.totalResenas} reseñas)"),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(onPressed: _openMap, icon: const Icon(Icons.map), label: const Text("CÓMO LLEGAR"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white)),
                  ),
                  const Divider(height: 40),
                  const Text("Reseñas", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  if (_isLoadingResenas) const Center(child: CircularProgressIndicator()),
                  if (!_isLoadingResenas && _resenas.isEmpty) const Text("No hay reseñas aún."),
                  ..._resenas.map((r) => ListTile(
                    title: Text(r['usuario_nombre'] ?? 'Usuario'),
                    subtitle: Text(r['comentario']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("${r['rating']} ⭐"),
                        if (r['usuario_id'] == _myUserId)
                          PopupMenuButton(
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'edit', child: Text("Editar")),
                              const PopupMenuItem(value: 'delete', child: Text("Eliminar")),
                            ],
                            onSelected: (val) {
                              if (val == 'edit') _showEditResena(r);
                              if (val == 'delete') _confirmEliminar(r['id']);
                            },
                          ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
