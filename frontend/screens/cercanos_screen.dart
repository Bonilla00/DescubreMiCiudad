import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/place_model.dart';
import '../widgets/restaurant_card.dart';
import 'details_screen.dart';

class CercanosScreen extends StatefulWidget {
  const CercanosScreen({super.key});

  @override
  State<CercanosScreen> createState() => _CercanosScreenState();
}

class _CercanosScreenState extends State<CercanosScreen> {
  List<Place> _lugares = [];
  List<Place> _filteredLugares = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Todos';
  final List<String> _filters = ['Todos', 'Comida', 'Bar', 'Popular'];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _searchController.addListener(_filterPlaces);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      final response =
          await http.get(Uri.parse("${ApiConstants.apiBaseUrl}/lugares"));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<Place> places = data
            .where((l) =>
                l['nombre'] != null &&
                !l['nombre'].toString().toLowerCase().contains('fundacion'))
            .map((l) => Place.fromJson(l))
            .toList();

        setState(() {
          _lugares = places;
          _filteredLugares = places;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterPlaces() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLugares = _lugares.where((place) {
        bool matchesSearch = place.nombre.toLowerCase().contains(query) ||
            place.categoria.toLowerCase().contains(query);
        bool matchesFilter = _selectedFilter == 'Todos' ||
            (_selectedFilter == 'Comida' &&
                place.categoria.toLowerCase().contains('restaurant')) ||
            (_selectedFilter == 'Bar' &&
                place.categoria.toLowerCase().contains('bar')) ||
            (_selectedFilter == 'Popular' && place.promedioCalificacion >= 4.0);
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Future<void> _refreshData() async {
    await _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header con título
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Restaurantes Cercanos',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF008A45),
                    ),
              ),
            ),

            // Buscador
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar restaurantes...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            // Filtros chips
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = filter);
                        _filterPlaces();
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: const Color(0xFF008A45).withOpacity(0.1),
                      checkmarkColor: const Color(0xFF008A45),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? const Color(0xFF008A45)
                            : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF008A45)
                              : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Lista de restaurantes
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredLugares.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.restaurant,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No se encontraron restaurantes',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _refreshData,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: _filteredLugares.length,
                            itemBuilder: (context, index) {
                              final place = _filteredLugares[index];
                              return RestaurantCard(
                                place: place,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailsScreen(place: place),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
