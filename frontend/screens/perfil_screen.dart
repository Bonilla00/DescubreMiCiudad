import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _authService = AuthService();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passActualController = TextEditingController();
  final _passNuevaController = TextEditingController();
  final _passConfirmController = TextEditingController();
  
  String? _fotoUrl;
  String? _fotoBase64;
  bool _isLoading = true;
  Map<String, dynamic>? _perfilData;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final data = await _authService.getPerfil(token);
      setState(() {
        _perfilData = data;
        _nombreController.text = data['nombre'] ?? '';
        _emailController.text = data['email'] ?? '';
        _fotoUrl = data['foto_url'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 500);
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() {
        _fotoBase64 = "data:image/png;base64,${base64Encode(bytes)}";
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (_passNuevaController.text.isNotEmpty && 
        _passNuevaController.text != _passConfirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final res = await _authService.actualizarPerfil(
      token: token,
      nombre: _nombreController.text,
      email: _emailController.text,
      passwordActual: _passActualController.text.isNotEmpty ? _passActualController.text : null,
      passwordNueva: _passNuevaController.text.isNotEmpty ? _passNuevaController.text : null,
      fotoUrl: _fotoBase64,
    );

    setState(() => _isLoading = false);
    if (res['success']) {
      await prefs.setString('nombre', _nombreController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perfil actualizado correctamente"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        actions: [
          IconButton(onPressed: _guardarCambios, icon: const Icon(Icons.save)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: (_fotoBase64 != null) 
                      ? MemoryImage(base64Decode(_fotoBase64!.split(',')[1])) 
                      : (_fotoUrl != null ? NetworkImage(_fotoUrl!) : null) as ImageProvider?,
                    child: (_fotoBase64 == null && _fotoUrl == null) 
                      ? const Icon(Icons.person, size: 50) 
                      : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.blue,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        onPressed: _seleccionarImagen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: "Nombre", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Correo", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ExpansionTile(
              title: const Text("Cambiar Contraseña"),
              children: [
                TextFormField(
                  controller: _passActualController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Contraseña actual"),
                ),
                TextFormField(
                  controller: _passNuevaController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Nueva contraseña"),
                ),
                TextFormField(
                  controller: _passConfirmController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Confirmar nueva contraseña"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat("Reseñas", "0"), // Podrían venir del perfilData si el backend lo retorna
                _buildStat("Favoritos", "0"),
                _buildStat("Miembro", _perfilData?['creado_en']?.toString().split('T')[0] ?? 'Hoy'),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardarCambios,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                child: const Text("GUARDAR CAMBIOS"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
