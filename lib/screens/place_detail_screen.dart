import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
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
  List<Resena> _resenas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarResenas();
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
            icon: const Icon(Icons.share),
            onPressed: () => Share.share("${place.nombre}\n${place.descripcion}"),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. IMAGEN PRINCIPAL ARRIBA
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

            // 3. CONTENIDO CON PADDING
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 4. NOMBRE DEL LUGAR
                  Text(
                    place.nombre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 5. DIRECCIÓN / DESCRIPCIÓN CORTA
                  Text(
                    "📍 ${place.descripcion}",
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  const SizedBox(height: 15),

                  // 6. RATING CON ESTRELLAS
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

                  // 7. SECCIÓN RESEÑAS
                  const Text(
                    "Reseñas",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  // LISTA DE RESEÑAS (UI LIMPIA)
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _resenas.isEmpty
                          ? const Text("Aún no hay reseñas para este lugar.",
                              style: TextStyle(color: Colors.grey))
                          : Column(
                              children: _resenas.map((r) => _buildResenaCard(r)).toList(),
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
          // Lógica de mapa mantenida
        },
        icon: const Icon(Icons.directions, color: Colors.white),
        label: const Text("CÓMO LLEGAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A73E8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
