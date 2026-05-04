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
  String? _email;
  String? _photoUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final nombre = await _authService.getNombre();
    final email = await _authService.getEmail();
    final photoUrl = await _authService.getPhotoURL();
    
    setState(() {
      _nombre = nombre ?? "";
      _email = email;
      _photoUrl = photoUrl;
    });

    try {
      final user = await _authService.getCurrentUser();
      final token = await user?.getIdToken();
      
      if (token != null) {
        final res = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/api/usuarios/estadisticas'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (res.statusCode == 200) {
          setState(() => _stats = jsonDecode(res.body));
        }
      }
    } catch (e) {
      print(e);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Perfil", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A73E8),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // FOTO DE PERFIL
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                    backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                    child: _photoUrl == null
                        ? const Icon(Icons.person, size: 60, color: Color(0xFF1A73E8))
                        : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // NOMBRE
                  Text(
                    _nombre,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  
                  // EMAIL
                  Text(
                    _email ?? "",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // VERIFICACIÓN DE EMAIL
                  if (_email != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 14, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Email verificado',
                            style: TextStyle(color: Colors.green, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 40),
                  
                  // ESTADÍSTICAS
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Mis Estadísticas",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Text(
                        "Miembro desde: ${DateFormat('d MMM yyyy', 'es').format(DateTime.parse(_stats!['miembro_desde']))}",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  
                  const Spacer(),
                  
                  // BOTÓN CERRAR SESIÓN
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Cerrar Sesión",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A73E8)),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
