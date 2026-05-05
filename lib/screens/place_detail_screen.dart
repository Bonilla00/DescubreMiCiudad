import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import '../models/place_model.dart';
import '../models/resena_model.dart';
import '../services/lugares_service.dart';
import '../services/auth_service.dart';

class PlaceDetailScreen extends StatefulWidget {
  final Place place;
  const PlaceDetailScreen({super.key, required this.place});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  final LugaresService _service = LugaresService();
  final AuthService _auth = AuthService();
  final TextEditingController _commentController = TextEditingController();
  
  List<Resena> _resenas = [];
  bool _isFavorite = false;
  bool _isLoggedIn = false;
  double _userRating = 5.0;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _cargarDatos();
  }

  void _checkStatus() async {
    final logged = await _auth.isLoggedIn();
    if (logged) {
      final favs = await _service.getFavoritos();
      if (mounted) {
        setState(() {
          _isLoggedIn = true;
          _isFavorite = favs.contains(widget.place.id);
        });
      }
    }
  }

  Future<void> _cargarDatos() async {
    final r = await _service.getResenas(widget.place.id);
    if (mounted) setState(() => _resenas = r);
  }

  void _toggleFav() async {
    if (!_isLoggedIn) return;
    await _service.toggleFavorito(widget.place.id, _isFavorite);
    setState(() => _isFavorite = !_isFavorite);
  }

  void _enviarResena() async {
    if (!_isLoggedIn || _commentController.text.isEmpty) return;
    final ok = await _service.publicarResena(widget.place.id, _commentController.text, _userRating.toInt());
    if (ok) {
      _commentController.clear();
      _cargarDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place.nombre, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A73E8),
        actions: [
          if (_isLoggedIn)
            IconButton(
              icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
              onPressed: _toggleFav,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(imageUrl: widget.place.imagenUrl, width: double.infinity, height: 230, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.place.nombre, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.place.descripcion),
                  const Divider(height: 40),
                  const Text("Reseñas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ..._resenas.map((r) => _buildResenaItem(r)),
                  if (_isLoggedIn) _buildAddResena(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResenaItem(Resena r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundImage: NetworkImage(r.avatar)),
        title: Text(r.usuario, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: List.generate(5, (i) => Icon(i < r.rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 14))),
            Text(r.comentario),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                  onPressed: () async {
                    await _service.toggleLike(r.id, false);
                    _cargarDatos();
                  },
                ),
                Text(r.likes.toString()),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAddResena() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 40),
        const Text("Escribe una reseña", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        RatingBar.builder(initialRating: 5, minRating: 1, itemSize: 25, itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber), onRatingUpdate: (r) => _userRating = r),
        TextField(controller: _commentController, decoration: const InputDecoration(hintText: "Tu opinión..."), maxLines: 2),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _enviarResena, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8)), child: const Text("PUBLICAR", style: TextStyle(color: Colors.white)))),
      ],
    );
  }
}
