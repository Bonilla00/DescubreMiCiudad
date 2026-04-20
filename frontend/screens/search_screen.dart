import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../services/lugares_service.dart';
import 'details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final LugaresService _service = LugaresService();
  List<Place> _results = [];
  bool _isLoading = false;

  void _onSearch() async {
    if (_searchController.text.isEmpty) return;
    setState(() => _isLoading = true);
    // Simulado por ahora con getLugares o podrías añadir buscar al servicio
    final res = await _service.getLugares(); 
    setState(() {
      _results = res.where((p) => p.nombre.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: "Buscar lugares...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
          onSubmitted: (_) => _onSearch(),
        ),
        actions: [
          IconButton(onPressed: _onSearch, icon: const Icon(Icons.search)),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final l = _results[index];
              return ListTile(
                title: Text(l.nombre),
                subtitle: Text(l.categoria),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DetailsScreen(place: l)),
                  );
                },
              );
            },
          ),
    );
  }
}
