import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../constants/api.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'mis_resenas_screen.dart';
import 'favoritos_screen.dart';
import 'change_password_screen.dart';

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

  int _resenasCount = 0;
  int _favoritosCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> refreshStats() async {
    await _cargarStats();
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

  String _getInitial() {
    if (_nombre.isEmpty) return "?";
    return _nombre[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
                  const SizedBox(height: 16),
                  _buildStats(),
                  const SizedBox(height: 16),
                  _buildSection("Información personal", [
                    _menuItem(Icons.person_outline, "Editar perfil", Colors.blue, () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(
                            nombreInicial: _nombre,
                            emailInicial: _email ?? "",
                          ),
                        ),
                      );
                      if (result == true) _loadData();
                    }),
                    _menuItem(Icons.chat_bubble_outline, "Mis reseñas", Colors.blue, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MisResenasScreen()));
                    }),
                    _menuItem(Icons.favorite_outline, "Mis favoritos", Colors.blue, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritosScreen()));
                    }),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection("Inicio de sesión y seguridad", [
                    _menuItem(Icons.lock_outline, "Cambiar contraseña", Colors.orange, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
                    }),
                    _menuItem(Icons.logout, "Cerrar sesión", Colors.red, _logout),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: const BoxDecoration(
        color: Color(0xFF1A73E8),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              _getInitial(),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
            ),
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
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem("$_resenasCount", "Reseñas"),
          Container(height: 40, width: 1, color: Colors.grey[300]),
          _statItem("$_favoritosCount", "Favoritos"),
        ],
      ),
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

  Widget _buildSection(String title, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A73E8)),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
