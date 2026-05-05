import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../constants/api.dart';

class EditProfileScreen extends StatefulWidget {
  final String nombreInicial;
  final String emailInicial;

  const EditProfileScreen({
    super.key,
    required this.nombreInicial,
    required this.emailInicial,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _authService = AuthService();
  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.nombreInicial);
    _emailController = TextEditingController(text: widget.emailInicial);
  }

  Future<void> _actualizarPerfil() async {
    if (_nombreController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor llena todos los campos")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = await _authService.getUserId();
      final response = await http.put(
        Uri.parse("${ApiConstants.baseUrl}/api/user/update/$userId"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': _nombreController.text,
          'email': _emailController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Perfil actualizado correctamente")),
          );
          Navigator.pop(context, true); // Retornamos true para recargar perfil
        }
      } else {
        throw Exception("Fallo al actualizar");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A73E8),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=descubremiciudad'),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: "Nombre completo",
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Correo electrónico",
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _actualizarPerfil,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("GUARDAR CAMBIOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
