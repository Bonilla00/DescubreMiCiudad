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
        setState(() {
          _lugares = jsonDecode(response.body);
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
        title: const Text("Restaurantes en Cali"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _lugares.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              final l = _lugares[index];
              final String imageUrl = l['imagen_url'] ?? 'https://via.placeholder.com/150';

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
                        errorBuilder: (_, __, ___) => Container(
                          height: 180,
                          color: Colors.grey[300],
                          child: const Icon(Icons.restaurant, size: 50),
                        ),
                      ),
                    ),
                    ListTile(
                      title: Text(l['nombre'] ?? "Sin nombre", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${l['categoria'] ?? 'Restaurante'} • ${l['precio'] ?? '\$\$'}"),
                      trailing: const Icon(Icons.star, color: Colors.amber),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
