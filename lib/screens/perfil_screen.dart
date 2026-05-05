import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../constants/api.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final AuthService _authService = AuthService();
  String _nombre = "";
  String? _email;
  bool _isLoading = true;

  // VARIABLES DINÁMICAS
  int _resenasCount = 0;
  int _favoritosCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final nombre = await _authService.getNombre();
    final email = await _authService.getEmail();
    
    if (mounted) {
      setState(() {
        _nombre = nombre ?? "Usuario";
        _email = email;
      });
    }

    // CARGAR ESTADÍSTICAS REALES
    await _cargarStats();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarStats() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return;

      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/api/user/stats/$userId"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _resenasCount = data['resenas'];
            _favoritosCount = data['favoritos'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error cargando stats: $e");
    }
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Mi Perfil", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A73E8),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildStats(),
                  const SizedBox(height: 30),
                  _buildProfileOptions(),
                  const SizedBox(height: 30),
                  _buildLogoutButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 30),
      decoration: const BoxDecoration(
        color: Color(0xFF1A73E8),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: const CircleAvatar(
                  radius: 55,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=descubremiciudad'),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Funcionalidad de cámara próximamente"))
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Color(0xFF1A73E8), size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _nombre,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            _email ?? "Sin correo",
            style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1A73E8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 30),
              elevation: 0,
            ),
            child: const Text("Editar Perfil", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statItem("$_resenasCount", "Reseñas"),
        Container(height: 40, width: 1, color: Colors.grey[300]),
        _statItem("$_favoritosCount", "Favoritos"),
      ],
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A73E8))),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildProfileOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _menuItem(Icons.lock_outline, "Cambiar contraseña", Colors.orange),
          _menuItem(Icons.chat_bubble_outline, "Mis reseñas", Colors.blue),
          _menuItem(Icons.star_border, "Mis favoritos", Colors.amber),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {},
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout),
          label: const Text("Cerrar Sesión", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[50],
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 0,
            side: BorderSide(color: Colors.red[100]!),
          ),
        ),
      ),
    );
  }
}
