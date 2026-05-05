import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/place_model.dart';
import '../models/resena_model.dart';
import '../services/lugares_service.dart';

class PlaceDetailScreen extends StatefulWidget {
  final Place place;
  const PlaceDetailScreen({super.key, required this.place});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  final LugaresService _service = LugaresService();
  final TextEditingController _controller = TextEditingController();
  
  List<Resena> _resenas = [];
  bool _loading = true;
  int _rating = 0;
  bool _isFavorite = false;
  bool _favoriteLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    await Future.wait([
      _cargarResenas(),
      _checkFavorite(),
    ]);
  }

  Future<void> _checkFavorite() async {
    final result = await _service.esFavorito(widget.place.id.toString());
    if (mounted) {
      setState(() => _isFavorite = result);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteLoading) return;

    final userId = await _service.getAuthService().getUserId();
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debes iniciar sesión para guardar favoritos"), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    setState(() => _favoriteLoading = true);
    final success = await _service.toggleFavorito(widget.place.id.toString(), _isFavorite);

    if (mounted) {
      if (success) {
        setState(() => _isFavorite = !_isFavorite);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isFavorite ? "Añadido a favoritos" : "Eliminado de favoritos"), duration: const Duration(seconds: 1)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al actualizar favoritos")));
      }
      setState(() => _favoriteLoading = false);
    }
  }

  Future<void> _cargarResenas() async {
    final r = await _service.getResenas(widget.place.id.toString());
    if (mounted) {
      setState(() {
        _resenas = r;
        _loading = false;
      });
    }
  }

  Future<void> _enviarResena() async {
    final userId = await _service.getAuthService().getUserId();
    if (userId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Inicia sesión para comentar"), backgroundColor: Colors.orange));
      return;
    }

    if (_rating == 0 || _controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Completa estrellas y comentario")));
      return;
    }

    final success = await _service.agregarResenaConRating(widget.place.id.toString(), _controller.text.trim(), _rating);

    if (success) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Reseña guardada!")));
      setState(() { _rating = 0; _controller.clear(); });
      _cargarResenas();
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al enviar reseña")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;

    return Scaffold(
      appBar: AppBar(
        title: Text(place.nombre, style: const TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFF1A73E8),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: _favoriteLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : Colors.white),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.share("${place.nombre}\n${place.descripcion}"),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroImage(place),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("📍 ${place.descripcion}", style: TextStyle(color: Colors.grey[700])),
                  const Divider(height: 32),
                  const Text("Reseñas de la comunidad", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildResenasList(),
                  const Divider(height: 48),
                  const Text("Danos tu calificación", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _buildReviewForm(),
                  const SizedBox(height: 32),
                  _buildMapButton(place),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage(Place place) {
    return CachedNetworkImage(
      imageUrl: place.imagenUrl,
      width: double.infinity,
      height: 220,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: Colors.grey[200]),
      errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size: 50)),
    );
  }

  Widget _buildResenasList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_resenas.isEmpty) return const Text("Aún no hay reseñas. ¡Sé el primero!", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic));
    
    return Column(
      children: _resenas.map((r) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        color: Colors.grey[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
        child: ListTile(
          leading: CircleAvatar(backgroundImage: NetworkImage(r.avatar)),
          title: Text(r.usuario, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: List.generate(5, (i) => Icon(i < r.rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 14))),
              const SizedBox(height: 4),
              Text(r.comentario),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildReviewForm() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) => IconButton(
            icon: Icon(index < _rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
            onPressed: () => setState(() => _rating = index + 1),
          )),
        ),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(hintText: "Escribe tu experiencia aquí...", border: OutlineInputBorder()),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _enviarResena,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8), foregroundColor: Colors.white),
            child: const Text("Publicar reseña", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildMapButton(Place place) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () async {
          final url = 'https://www.google.com/maps/search/?api=1&query=${place.lat},${place.lng}';
          if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        },
        icon: const Icon(Icons.directions, color: Colors.white),
        label: const Text("¿CÓMO LLEGAR?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      ),
    );
  }
}
