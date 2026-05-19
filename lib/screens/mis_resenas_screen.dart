import 'package:flutter/material.dart';
import '../models/resena_model.dart';
import '../services/lugares_service.dart';
import '../services/auth_service.dart';

class MisResenasScreen extends StatefulWidget {
  const MisResenasScreen({super.key});

  @override
  State<MisResenasScreen> createState() => _MisResenasScreenState();
}

class _MisResenasScreenState extends State<MisResenasScreen> {
  final LugaresService _service = LugaresService();
  final AuthService _authService = AuthService();
  List<Resena> _misResenas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarMisResenas();
  }

  Future<void> _cargarMisResenas() async {
    final userId = await _authService.getUserId();
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final resenas = await _service.getResenasUsuario(userId.toString());
    if (mounted) {
      setState(() {
        _misResenas = resenas;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Mis reseñas", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _misResenas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text("Aún no tienes reseñas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text("Tus opiniones sobre lugares aparecerán aquí.", style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _misResenas.length,
                  itemBuilder: (context, index) {
                    final resena = _misResenas[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(backgroundImage: NetworkImage(resena.avatar)),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(resena.usuario, style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (resena.lugarNombre.isNotEmpty) Text(resena.lugarNombre, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(children: List.generate(5, (i) => Icon(i < resena.rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 14))),
                            const SizedBox(height: 4),
                            Text(resena.comentario),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
