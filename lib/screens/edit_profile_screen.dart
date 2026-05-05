import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../constants/api.dart';

class EditProfileScreen extends StatefulWidget {
  final String nombreInicial;
  final String emailInicial;
  final String avatarInicial;

  const EditProfileScreen({
    super.key,
    required this.nombreInicial,
    required this.emailInicial,
    required this.avatarInicial,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _authService = AuthService();
  late TextEditingController nombreController;
  late TextEditingController emailController;
  bool _isLoading = false;
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String _currentAvatarUrl = "";

  @override
  void initState() {
    super.initState();
    nombreController = TextEditingController(text: widget.nombreInicial);
    emailController = TextEditingController(text: widget.emailInicial);
    _currentAvatarUrl = widget.avatarInicial;
  }

  @override
  void dispose() {
    nombreController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Error al seleccionar imagen: $e");
    }
  }

  Future<void> actualizarPerfil() async {
    final nombre = nombreController.text.trim();
    final email = emailController.text.trim();

    if (nombre.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor rellena todos los campos")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = await _authService.getUserId();
      if (userId == null) throw Exception("No se encontró el ID de usuario");

      String? avatarBase64;
      if (_imageFile != null) {
        // En una app real subiríamos a S3/Cloudinary, aquí simulamos con base64 o mantenemos la URL si no hay cambio
        final bytes = await _imageFile!.readAsBytes();
        avatarBase64 = "data:image/png;base64,${base64Encode(bytes)}";
      }

      final response = await http.put(
        Uri.parse("${ApiConstants.baseUrl}/api/user/update/$userId"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'email': email,
          'avatar': avatarBase64 ?? _currentAvatarUrl,
        }),
      );

      if (response.statusCode == 200) {
        // ACTUALIZAR DATOS LOCALES ANTES DE VOLVER
        await _authService.updateLocalUserData(nombre, email, avatarBase64 ?? _currentAvatarUrl);
        
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Perfil actualizado correctamente")),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? "Error al actualizar");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Editar Perfil", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _imageFile != null 
                        ? FileImage(_imageFile!) 
                        : NetworkImage(_currentAvatarUrl) as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: const CircleAvatar(
                        backgroundColor: Color(0xFF1A73E8),
                        radius: 20,
                        child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text("Nombre completo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: nombreController,
              decoration: InputDecoration(
                hintText: "Tu nombre",
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Correo electrónico", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "tu@email.com",
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : actualizarPerfil,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Guardar cambios", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
