import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
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
  final TextEditingController _commentController = TextEditingController();
  
  double _promedio = 0.0;
  int _total = 0;
  List<Resena> _resenas = [];
  bool _loadingResenas = true;
  double _userRating = 5.0;

  @override
  void initState() {
    super.initState();
    _cargarResenas();
  }

  Future<void> _cargarResenas() async {
    final r = await _service.getResenas(widget.place.id);
    final p = await _service.getPromedio(widget.place.id);

    if (mounted) {
      setState(() {
        _resenas = r;
        _promedio = double.tryParse(p['promedio'].toString()) ?? 0.0;
        _total = p['total'] ?? 0;
        _loadingResenas = false;
      });
    }
  }

  void _enviarResena() async {
    if (_commentController.text.isEmpty) return;
    final ok = await _service.publicarResena(widget.place.id, _commentController.text, _userRating.toInt());
    if (ok) {
      _commentController.clear();
      _cargarResenas();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reseña enviada")));
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl: widget.place.imagenUrl,
              width: double.infinity,
              height: 230,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.place.nombre, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  // SECCIÓN PROMEDIO
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 28),
                      const SizedBox(width: 4),
                      Text(_promedio.toStringAsFixed(1), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(" ($_total reseñas)", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const Divider(height: 30),
                  const Text("Descripción", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(widget.place.descripcion),
                  
                  const SizedBox(height: 20),
                  _buildMapButton(),
                  
                  const Divider(height: 40),
                  
                  // SECCIÓN COMENTARIOS
                  const Text("Reseñas de la comunidad", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _loadingResenas 
                    ? const Center(child: CircularProgressIndicator())
                    : _buildResenasList(),
                  
                  const Divider(height: 40),
                  
                  // FORMULARIO NUEVA RESEÑA
                  const Text("Deja tu opinión", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  RatingBar.builder(
                    initialRating: 5,
                    minRating: 1,
                    itemSize: 30,
                    itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (r) => _userRating = r,
                  ),
                  TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(hintText: "Escribe tu comentario...", border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _enviarResena,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8)),
                      child: const Text("PUBLICAR", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResenasList() {
    if (_resenas.isEmpty) return const Text("Aún no hay reseñas. ¡Sé el primero!");
    return Column(
      children: _resenas.map((r) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: const CircleAvatar(backgroundColor: Color(0xFF1A73E8), child: Icon(Icons.person, color: Colors.white)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(r.usuario, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(r.fecha)), style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: List.generate(5, (i) => Icon(i < r.rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 14))),
              Text(r.comentario),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildMapButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final url = 'https://www.google.com/maps/search/?api=1&query=${widget.place.lat},${widget.place.lng}';
          if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        },
        icon: const Icon(Icons.map, color: Colors.white),
        label: const Text("CÓMO LLEGAR", style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
      ),
    );
  }
}
