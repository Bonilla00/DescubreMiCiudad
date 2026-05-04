import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place_model.dart';
import '../services/lugares_service.dart';
import '../services/auth_service.dart';
import '../services/favoritos_service.dart';

class PlaceDetailScreen extends StatefulWidget {
  final Place place;
  const PlaceDetailScreen({super.key, required this.place});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  final LugaresService _lugaresService = LugaresService();
  final AuthService _authService = AuthService();
  final FavoritosService _favoritosService = FavoritosService();
  final _commentController = TextEditingController();
  
  Map<String, dynamic>? _detalle;
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isFavorito = false;
  double _userRating = 5.0;
  int _visitas = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _incrementVisitas();
  }

  void _incrementVisitas() async {
    final prefs = await SharedPreferences.getInstance();
    int v = prefs.getInt('visitas_${widget.place.id}') ?? 0;
    v++;
    await prefs.setInt('visitas_${widget.place.id}', v);
    setState(() => _visitas = v);
  }

  void _loadData() async {
    final detail = await _lugaresService.getLugarById(widget.place.id);
    final logged = await _authService.isLoggedIn();
    bool fav = false;
    if (logged) {
      fav = await _favoritosService.checkFavorito(widget.place.id);
    }
    
    if (mounted) {
      setState(() {
        _detalle = detail;
        _isLoggedIn = logged;
        _isFavorito = fav;
        _isLoading = false;
      });
    }
  }

  void _toggleFav() async {
    if (!_isLoggedIn) return;
    final res = await _favoritosService.toggleFavorito(widget.place.id);
    setState(() => _isFavorito = res);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res ? 'Agregado a favoritos' : 'Eliminado de favoritos'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _submitResena() async {
    if (_commentController.text.isEmpty) return;
    
    final user = _authService.getCurrentUser();

    final response = await _lugaresService.agregarResenaConRating(
      widget.place.id, 
      _commentController.text,
      _userRating.toInt(),
    );

    if (response) {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.share("${widget.place.nombre}\n${widget.place.descripcion}"),
          ),
          if (_isLoggedIn)
            IconButton(
              icon: Icon(_isFavorito ? Icons.favorite : Icons.favorite_border, color: _isFavorito ? Colors.red : Colors.white),
              onPressed: _toggleFav,
            ),
        ],
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
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(label: Text(widget.place.categoria)),
                            Row(
                              children: [
                                const Icon(Icons.remove_red_eye, size: 16, color: Colors.grey),
                                Text(" $_visitas visitas", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text("${_detalle?['promedio_rating']?.toStringAsFixed(1) ?? '0.0'}", 
                                 style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A73E8))),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RatingBarIndicator(
                                  rating: (_detalle?['promedio_rating'] ?? 0.0).toDouble(),
                                  itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                                  itemCount: 5,
                                  itemSize: 20.0,
                                ),
                                Text("${_detalle?['total_resenas'] ?? 0} reseñas", style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoSection(),
                        const SizedBox(height: 16),
                        _buildMapButton(),
                        const Divider(height: 32),
                        const Text("Descripción", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(widget.place.descripcion),
                        const Divider(height: 32),
                        _buildResenasList(),
                        if (_isLoggedIn) _buildAddResena(),
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          _infoRow(Icons.access_time, "Lun-Vie: 8AM-10PM / Sab-Dom: 10AM-11PM"),
          _infoRow(Icons.phone, "+57 300 000 0000"),
          _infoRow(Icons.language, "www.descubremiciudad.com"),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [Icon(icon, size: 16, color: Colors.blue), const SizedBox(width: 8), Text(text, style: const TextStyle(fontSize: 13))]),
    );
  }

  Widget _buildMapButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () async {
          final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${widget.place.lat},${widget.place.lng}');
          if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        icon: const Icon(Icons.map_outlined),
        label: const Text('Ver en Google Maps'),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
      ),
    );
  }

  Widget _buildResenasList() {
    final resenas = _detalle?['resenas'] as List? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Reseñas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (resenas.isEmpty) const Text("Sé el primero en opinar", style: TextStyle(color: Colors.grey)),
        ...resenas.map((res) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(res['usuario_nombre'] ?? 'Usuario', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(DateFormat('d MMM yyyy', 'es').format(DateTime.parse(res['fecha'])), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RatingBarIndicator(rating: (res['rating'] ?? 5).toDouble(), itemCount: 5, itemSize: 14, itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber)),
                const SizedBox(height: 4),
                Text(res['comentario']),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildAddResena() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Text("Danos tu opinión", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        RatingBar.builder(
          initialRating: 5,
          minRating: 1,
          itemCount: 5,
          itemSize: 30,
          itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
          onRatingUpdate: (rating) => setState(() => _userRating = rating),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _commentController,
          decoration: InputDecoration(hintText: 'Escribe tu experiencia...', filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _submitResena, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8), foregroundColor: Colors.white), child: const Text("Publicar Reseña"))),
      ],
    );
  }
}
