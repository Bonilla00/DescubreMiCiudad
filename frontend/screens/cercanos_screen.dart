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
      print("PETICIÓN A: ${ApiConstants.apiBaseUrl}/lugares");
      final response = await http.get(Uri.parse("${ApiConstants.apiBaseUrl}/lugares"));
      
      print("RESPUESTA STATUS: ${response.statusCode}");
      print("RESPUESTA BODY: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          _lugares = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("ERROR CARGANDO: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lugares en Cali")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _lugares.isEmpty 
          ? const Center(child: Text("No hay datos disponibles"))
          : ListView.builder(
              itemCount: _lugares.length,
              itemBuilder: (context, index) {
                final l = _lugares[index];
                return ListTile(
                  leading: const Icon(Icons.restaurant, color: Colors.orange),
                  title: Text(l['nombre'] ?? "Sin nombre"),
                  subtitle: Text(l['categoria'] ?? "Restaurante"),
                  trailing: const Icon(Icons.chevron_right),
                );
              },
            ),
    );
  }
}
