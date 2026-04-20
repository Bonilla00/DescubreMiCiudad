import 'dart:async';
import 'package:flutter/material.dart';
import '../services/lugares_service.dart';
import '../models/place_model.dart';
import 'place_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final LugaresService _lugaresService = LugaresService();
  List<Place> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  String? _selectedCategoria;
  String? _selectedPrecio;
  bool _showFilters = false;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  void _performSearch() async {
    setState(() => _isLoading = true);
    final data = await _lugaresService.buscarLugares(
      q: _searchController.text,
      categoria: _selectedCategoria,
      precio: _selectedPrecio,
    );
    if (mounted) {
      setState(() {
        _results = data.map((item) => Place.fromJson(item)).toList();
        _isLoading = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategoria = null;
      _selectedPrecio = null;
    });
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Buscar lugares...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
                    onPressed: () => setState(() => _showFilters = !_showFilters),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_showFilters) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text("Categoría"),
                        value: _selectedCategoria,
                        items: ["Cafés", "Discotecas", "Restaurante"].map((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text(value));
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedCategoria = val);
                          _performSearch();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text("Precio"),
                        value: _selectedPrecio,
                        items: ["Economico", "Caro"].map((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text(value));
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedPrecio = val);
                          _performSearch();
                        },
                      ),
                    ),
                  ],
                ),
                TextButton(onPressed: _clearFilters, child: const Text("Limpiar filtros"))
              ]
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
                  ? const Center(child: Text("No se encontraron resultados"))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final place = _results[index];
                        return ListTile(
                          title: Text(place.nombre),
                          subtitle: Text("${place.categoria} • ${place.distancia}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Color(0xFFF59E0B), size: 18),
                              Text(place.rating.toString()),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => PlaceDetailScreen(place: place)),
                            );
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
