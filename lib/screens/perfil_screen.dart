import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _stats;
  String _nombre = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final token = await _authService.getToken();
    final nombre = await _authService.getNombre();
    setState(() => _nombre = nombre ?? "");
    
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/usuarios/estadisticas'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) setState(() => _stats = jsonDecode(res.body));
    } catch (e) {
      print(e);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mi Perfil", style: TextStyle(color: Colors.white)), backgroundColor: Colors.blue, iconTheme: const IconThemeData(color: Colors.white)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(radius: 50, backgroundColor: Colors.blue, child: Icon(Icons.person, size: 60, color: Colors.white)),
                  const SizedBox(height: 16),
                  Text(_nombre, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Divider(height: 40),
                  const Text("Mis Estadísticas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statCard("Reseñas", _stats?['total_resenas']?.toString() ?? "0"),
                      _statCard("Favoritos", _stats?['total_favoritos']?.toString() ?? "0"),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_stats?['miembro_desde'] != null)
                    Text("Miembro desde: ${DateFormat('d MMM yyyy', 'es').format(DateTime.parse(_stats!['miembro_desde']))}"),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _authService.logout();
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      child: const Text("Cerrar Sesión"),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
      child: Column(children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)), Text(label, style: const TextStyle(fontSize: 12))]),
    );
  }
}
