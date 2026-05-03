import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _authService = AuthService();
  bool _isLoading = true;
  Map<String, dynamic>? _perfilData;
  String? _nombre;
  String? _fotoUrl;

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
        _nombre = data['nombre'];
        _fotoUrl = data['foto_url'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cerrar sesión"),
        content: const Text("¿Estás seguro de que deseas salir?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("CERRAR SESIÓN", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _irAEditarPerfil() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          perfilData: _perfilData!,
          onUpdate: _cargarPerfil,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajustes"),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: ListView(
        children: [
          // Header estilo WhatsApp
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Hero(
              tag: 'profile_pic',
              child: CircleAvatar(
                radius: 30,
                backgroundImage: (_fotoUrl != null && _fotoUrl!.isNotEmpty)
                    ? NetworkImage(_fotoUrl!)
                    : null,
                child: (_fotoUrl == null || _fotoUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 35)
                    : null,
              ),
            ),
            title: Text(
              _nombre ?? "Usuario",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _perfilData?['email'] ?? "Disponible",
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: const Icon(Icons.qr_code, color: Colors.blue),
            onTap: _irAEditarPerfil,
          ),
          const Divider(height: 1),

          _buildOption(Icons.key, "Cuenta", "Notificaciones de seguridad, cambiar número"),
          _buildOption(Icons.lock, "Privacidad", "Bloqueo de contactos, mensajes temporales"),
          _buildOption(Icons.face, "Avatar", "Crear, editar, foto de perfil"),
          _buildOption(Icons.favorite_border, "Favoritos", "Mis lugares guardados"),
          _buildOption(Icons.notifications_none, "Notificaciones", "Tonos de mensajes, grupos y llamadas"),
          _buildOption(Icons.storage_outlined, "Almacenamiento y datos", "Uso de red, descarga automática"),
          _buildOption(Icons.language, "Idioma de la aplicación", "Español (idioma del dispositivo)"),
          _buildOption(Icons.help_outline, "Ayuda", "Centro de ayuda, contáctanos, política de privacidad"),
          _buildOption(Icons.group_outlined, "Invitar a un amigo", null),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Cerrar sesión", style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),

          const SizedBox(height: 30),
          Column(
            children: [
              const Text("from", style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text(
                "DESCUBRE MI CIUDAD",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.blue.shade800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildOption(IconData icon, String title, String? subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13))
          : null,
      onTap: () {
        // Implementar según necesidad
      },
    );
  }
}

// Nueva pantalla para editar el perfil, similar a la de WhatsApp
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> perfilData;
  final VoidCallback onUpdate;

  const EditProfileScreen({super.key, required this.perfilData, required this.onUpdate});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  String? _fotoUrl;
  String? _fotoBase64;
  final _authService = AuthService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.perfilData['nombre']);
    _emailController = TextEditingController(text: widget.perfilData['email']);
    _fotoUrl = widget.perfilData['foto_url'];
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

  Future<void> _guardar() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final res = await _authService.actualizarPerfil(
      token: token,
      nombre: _nombreController.text,
      email: _emailController.text,
      fotoUrl: _fotoBase64,
    );

    setState(() => _isSaving = false);
    if (res['success']) {
      widget.onUpdate();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perfil actualizado"), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Perfil")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  Hero(
                    tag: 'profile_pic',
                    child: CircleAvatar(
                      radius: 80,
                      backgroundImage: (_fotoBase64 != null)
                        ? MemoryImage(base64Decode(_fotoBase64!.split(',')[1]))
                        : (_fotoUrl != null && _fotoUrl!.isNotEmpty ? NetworkImage(_fotoUrl!) : null) as ImageProvider?,
                      child: (_fotoBase64 == null && (_fotoUrl == null || _fotoUrl!.isEmpty))
                        ? const Icon(Icons.person, size: 80)
                        : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 5,
                    child: CircleAvatar(
                      backgroundColor: Colors.blue,
                      radius: 25,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _seleccionarImagen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildEditTile(Icons.person_outline, "Nombre", _nombreController, "Este no es un nombre de usuario ni un PIN. Este nombre será visible para tus contactos de DescubreMiCiudad."),
            const Divider(indent: 70),
            _buildEditTile(Icons.info_outline, "Info.", TextEditingController(text: "¡Hola! Estoy usando DescubreMiCiudad."), null),
            const Divider(indent: 70),
            _buildEditTile(Icons.email_outlined, "Correo", _emailController, null),
            const SizedBox(height: 40),
            if (_isSaving) const CircularProgressIndicator()
            else Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text("GUARDAR", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditTile(IconData icon, String label, TextEditingController controller, String? description) {
    return ListTile(
      leading: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Icon(icon, color: Colors.grey),
      ),
      title: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              suffixIcon: Icon(Icons.edit, size: 18, color: Colors.blue),
            ),
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
          if (description != null)
            Text(description, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
