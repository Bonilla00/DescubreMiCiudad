import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/place_model.dart';
import '../services/lugares_service.dart';
import '../services/auth_service.dart';

class PlaceDetailScreen extends StatefulWidget {
  final Place place;
  const PlaceDetailScreen({super.key, required this.place});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  final LugaresService _lugaresService = LugaresService();
  final AuthService _authService = AuthService();
  final _commentController = TextEditingController();
  Map<String, dynamic>? _detalle;
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final detail = await _lugaresService.getLugarById(widget.place.id);
    final logged = await _authService.isLoggedIn();
    if (mounted) {
      setState(() {
        _detalle = detail;
        _isLoggedIn = logged;
        _isLoading = false;
      });
    }
  }

  void _submitResena() async {
    if (_commentController.text.isEmpty) return;
    
    final success = await _lugaresService.agregarResena(
      widget.place.id, 
      _commentController.text
    );

    if (success) {
      _commentController.clear();
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reseña publicada'), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place.nombre, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A73E8),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.place.imagenUrl,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 250,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => const SizedBox(
                      height: 250,
                      child: Center(child: Icon(Icons.image_not_supported, size: 50)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              label: Text(widget.place.categoria),
                              backgroundColor: const Color(0xFFF5F5F5),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Color(0xFFF59E0B)),
                                Text(" ${widget.place.rating}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                        Text("Precio: ${widget.place.precio} (${widget.place.priceLevel})", 
                             style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        const Text("Descripción", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(widget.place.descripcion),
                        const Divider(height: 32),
                        const Text("Reseñas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        if (_detalle?['resenas'] != null)
                          ...(_detalle!['resenas'] as List).map((res) => ListTile(
                                title: Text(res['usuario_nombre'] ?? 'Usuario'),
                                subtitle: Text(res['comentario']),
                                trailing: Text(res['fecha'].toString().split('T')[0]),
                              )),
                        if (_isLoggedIn) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Escribe una reseña...',
                              filled: true,
                              fillColor: const Color(0xFFF5F5F5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _submitResena,
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(const Color(0xFF1A73E8)),
                              foregroundColor: WidgetStateProperty.all(Colors.white),
                            ),
                            child: const Text("Publicar Reseña"),
                          )
                        ]
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
