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
    final result = await _service.esFavorito(widget.place.id);
    if (mounted) {
      setState(() {
        _isFavorite = result;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteLoading) return;

    setState(() => _favoriteLoading = true);
    
    // 🔥 LOGS PARA DEPURACIÓN
    final userId = await _service.getAuthService().getUserId();
    debugPrint("DEBUG FAVORITOS - USER ID: $userId");
    debugPrint("DEBUG FAVORITOS - PLACE ID: ${widget.place.id}");

    final success = await _service.toggleFavorito(widget.place.id, _isFavorite);

    if (mounted) {
      if (success) {
        setState(() {
          _isFavorite = !_isFavorite;
          _favoriteLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? "Añadido a favoritos" : "Eliminado de favoritos"),
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        setState(() => _favoriteLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al actualizar favoritos")),
        );
      }
    }
  }

  Future<void> _cargarResenas() async {
    final r = await _service.getResenas(widget.place.id);
    if (mounted) {
      setState(() {
        _resenas = r;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;

    return Scaffold(
      appBar: AppBar(
        title: Text(place.nombre, style: const TextStyle(color: Colors.white)),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl: place.imagenUrl,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[200]),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, size: 50),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.nombre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    "📍 ${place.descripcion}",
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < place.rating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 24,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        place.rating.toString(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Divider(),
                  const SizedBox(height: 10),

                  const Text(
                    "Reseñas",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _resenas.isEmpty
                          ? const Text("Aún no hay reseñas para este lugar.",
                              style: TextStyle(color: Colors.grey))
                          : Column(
                              children: _resenas.map((r) => _buildResenaCard(r)).toList(),
                            ),
                  
                  // --- FORMULARIO DE RESEÑAS ---
                  const SizedBox(height: 30),
                  const Divider(),
                  const Text(
                    "Danos tu opinión",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  
                  // WIDGET DE ESTRELLAS
                  Row(
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  
                  // CAMPO DE TEXTO
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Escribe tu comentario...",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 15),
                  
                  // BOTÓN ENVIAR
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_rating == 0 || _controller.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Completa todos los campos")),
                          );
                          return;
                        }

                        final success = await _service.agregarResenaConRating(
                          place.id,
                          _controller.text,
                          _rating,
                        );

                        if (success) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Reseña enviada")),
                            );
                          }

                          setState(() {
                            _rating = 0;
                            _controller.clear();
                          });
                          
                          // Recargar reseñas para mostrar la nueva
                          _cargarResenas();
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Error al enviar")),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Enviar reseña"),
                    ),
                  ),

                  const SizedBox(height: 30),
                  _buildMapButton(place),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResenaCard(Resena r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 15,
                backgroundColor: Color(0xFF1A73E8),
                child: Icon(Icons.person, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(r.usuario, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) => Icon(
              i < r.rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 14,
            )),
          ),
          const SizedBox(height: 5),
          Text(r.comentario, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildMapButton(Place place) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () async {
          final url = 'https://www.google.com/maps/search/?api=1&query=${place.lat},${place.lng}';
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          }
        },
        icon: const Icon(Icons.directions, color: Colors.white),
        label: const Text("CÓMO LLEGAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
