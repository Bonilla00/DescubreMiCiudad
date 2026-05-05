import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:share_plus/share_plus.dart';
import '../models/place_model.dart';

class PlaceDetailScreen extends StatelessWidget {
  final Place place;

  const PlaceDetailScreen({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    // Explicación: Se eliminó el loading infinito al usar directamente el objeto 'place'.
    // Ya no se llama a getLugarById() ni se usa FutureBuilder.
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
            // 1. IMAGEN DEL LUGAR
            CachedNetworkImage(
              imageUrl: place.imagenUrl,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[200]),
              errorWidget: (context, url, error) => const Icon(Icons.image_not_supported),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. CATEGORÍA
                  Chip(
                    label: Text(place.categoria),
                    backgroundColor: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 8),
                  
                  // 3. NOMBRE Y RATING
                  Text(
                    place.nombre,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: place.rating,
                        itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                        itemCount: 5,
                        itemSize: 24.0,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        place.rating.toString(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Text(place.precio, style: const TextStyle(color: Colors.grey, fontSize: 18)),
                    ],
                  ),
                  
                  const Divider(height: 32),
                  
                  // 4. DESCRIPCIÓN
                  const Text(
                    "Descripción",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    place.descripcion,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 5. BOTÓN CÓMO LLEGAR
                  _buildMapButton(context),
                  
                  const SizedBox(height: 32),
                  
                  // INFO ADICIONAL (Estática)
                  _infoRow(Icons.access_time, "Horario: 8AM - 10PM"),
                  _infoRow(Icons.phone, "Contacto: Cali Sur"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () async {
          final url = 'https://www.google.com/maps/search/?api=1&query=${place.lat},${place.lng}';
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          }
        },
        icon: const Icon(Icons.directions, color: Colors.white),
        label: const Text('CÓMO LLEGAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A73E8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1A73E8)),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
