import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';

class CercanosScreen extends StatefulWidget {
  const CercanosScreen({super.key});

  @override
  State<CercanosScreen> createState() => _CercanosScreenState();
}

class _CercanosScreenState extends State<CercanosScreen> {
  List<dynamic> _lugares = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final response = await http.get(Uri.parse("${ApiConstants.apiBaseUrl}/lugares"));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        
        // Filtro de seguridad: Solo restaurantes con nombre válido
        setState(() {
          _lugares = data.where((l) => 
            l['nombre'] != null && 
            !l['nombre'].toString().toLowerCase().contains('fundacion')
          ).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Restaurantes Reales Cali"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _lugares.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              final l = _lugares[index];
              final String imageUrl = l['imagen_url'] ?? 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4';
              final double rating = (l['rating'] ?? 4.0).toDouble();

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: Image.network(
                        imageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.network(
                          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    ListTile(
                      title: Text(
                        l['nombre'] ?? "Restaurante", 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold)
                      ),
                      subtitle: Text("${l['categoria'] ?? 'Restaurante'} • ${l['precio'] ?? '\$\$'}"),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
