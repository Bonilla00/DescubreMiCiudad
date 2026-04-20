import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place_model.dart';
import '../services/lugares_service.dart';
import 'place_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final LugaresService _lugaresService = LugaresService();
  final TextEditingController _searchController = TextEditingController();
  List<Place> _allPlaces = [];
  List<Place> _filteredPlaces = [];
  List<String> _history = [];
  bool _isLoading = true;
  double? _userLat;
  double? _userLng;

  // FILTROS
  String _selectedCat = "Todos";
  String _selectedPrice = "Todos";
  int _minRating = 0;
  String _sortOption = "Mejor valorados";

  final List<String> _categorias = ["Todos", "Restaurante", "Cafés", "Discotecas"];
  final List<String> _precios = ["Todos", "\$ Económico", "\$\$ Caro"];

  @override
  void initState() {
    super.initState();
    _initUbicacionYLoad();
    _loadHistory();
  }

  Future<void> _initUbicacionYLoad() async {
    try {
      Position? pos = await Geolocator.getCurrentPosition(timeLimit: const Duration(seconds: 5)).catchError((_) => null);
      if (pos != null) {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
      }
    } catch (e) {
      debugPrint("Error ubicacion background: $e");
    }
    _loadAll();
  }

  void _loadAll() async {
    final list = await _lugaresService.getLugares(lat: _userLat, lng: _userLng);
    if (mounted) {
      setState(() {
        _allPlaces = list;
        _filteredPlaces = _allPlaces;
        _isLoading = false;
      });
    }
  }

  void _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _history = prefs.getStringList('search_history') ?? []);
  }

  void _saveHistory(String q) async {
    if (q.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _history.remove(q);
    _history.insert(0, q);
    if (_history.length > 5) _history.removeLast();
    await prefs.setStringList('search_history', _history);
    setState(() {});
  }

  void _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    setState(() => _history = []);
  }

  void _applyFilters() {
    List<Place> filtered = _allPlaces.where((p) {
      bool catMatch = _selectedCat == "Todos" || p.categoria == _selectedCat;
      bool priceMatch = _selectedPrice == "Todos" || (_selectedPrice == "\$ Económico" ? p.priceLevel == "Economico" : p.priceLevel == "Caro");
      bool ratingMatch = p.rating >= _minRating;
      bool textMatch = _searchController.text.isEmpty || p.nombre.toLowerCase().contains(_searchController.text.toLowerCase());
      return catMatch && priceMatch && ratingMatch && textMatch;
    }).toList();

    // SORTING
    if (_sortOption == "Mejor valorados") {
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortOption == "Nombre A-Z") {
      filtered.sort((a, b) => a.nombre.compareTo(b.nombre));
    } else if (_sortOption == "Precio menor") {
      filtered.sort((a, b) => a.priceLevel.compareTo(b.priceLevel));
    }

    setState(() => _filteredPlaces = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBox(),
            if (_searchController.text.isEmpty && _history.isNotEmpty) _buildHistory(),
            _buildFilterBar(),
            _buildFilterChips(),
            _buildResultCounter(),
            Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onSubmitted: (v) { _saveHistory(v); _applyFilters(); },
        onChanged: (_) => _applyFilters(),
        decoration: InputDecoration(
          hintText: "Busca tu lugar...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _applyFilters(); }) : null,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildHistory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: const [Icon(Icons.history, size: 16), SizedBox(width: 8), Text("Recientes")]),
              TextButton(onPressed: _clearHistory, child: const Text("Limpiar", style: TextStyle(color: Colors.red))),
            ],
          ),
          Wrap(
            spacing: 8,
            children: _history.map((q) => ActionChip(label: Text(q), onPressed: () { _searchController.text = q; _applyFilters(); })).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _filterDropdown("Ordenar", ["Mejor valorados", "Nombre A-Z", "Precio menor"], (v) { setState(() => _sortOption = v!); _applyFilters(); }),
          const SizedBox(width: 8),
          _filterDropdown("Categoría", _categorias, (v) { setState(() => _selectedCat = v!); _applyFilters(); }),
          const SizedBox(width: 8),
          _filterDropdown("Precio", _precios, (v) { setState(() => _selectedPrice = v!); _applyFilters(); }),
        ],
      ),
    );
  }

  Widget _filterDropdown(String label, List<String> options, Function(String?)? onChange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(label),
          items: options.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: onChange,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    List<Widget> chips = [];
    if (_selectedCat != "Todos") chips.add(_chip(_selectedCat, () => setState(() { _selectedCat = "Todos"; _applyFilters(); })));
    if (_selectedPrice != "Todos") chips.add(_chip(_selectedPrice, () => setState(() { _selectedPrice = "Todos"; _applyFilters(); })));
    if (_minRating > 0) chips.add(_chip("★ $_minRating+", () => setState(() { _minRating = 0; _applyFilters(); })));

    if (chips.isEmpty) return const SizedBox();
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [Expanded(child: ListView(scrollDirection: Axis.horizontal, children: chips)), TextButton(onPressed: () { setState(() { _selectedCat = "Todos"; _selectedPrice = "Todos"; _minRating = 0; }); _applyFilters(); }, child: const Text("Limpiar todo", style: TextStyle(color: Colors.red, fontSize: 12)))]),
    );
  }

  Widget _chip(String label, VoidCallback onDel) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(label: Text(label, style: const TextStyle(fontSize: 12)), deleteIcon: const Icon(Icons.close, size: 14), onDeleted: onDel),
    );
  }

  Widget _buildResultCounter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [Text("${_filteredPlaces.length} lugares encontrados", style: const TextStyle(color: Colors.grey, fontSize: 12))]),
    );
  }

  Widget _buildResults() {
    if (_filteredPlaces.isEmpty) return const Center(child: Text("No se encontraron resultados"));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredPlaces.length,
      itemBuilder: (context, i) {
        final p = _filteredPlaces[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: p.imagenUrl, width: 60, height: 60, fit: BoxFit.cover, errorWidget: (c,u,e)=>const Icon(Icons.image))),
            title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${p.categoria} • ${p.precio} • ★${p.rating}"),
                if (p.distanciaInfo != null) 
                  Row(
                    children: [
                      const Icon(Icons.place, size: 12, color: Color(0xFF1A73E8)),
                      Text(" ${p.distanciaInfo!.distanciaTexto} ", style: const TextStyle(fontSize: 11)),
                      const Icon(Icons.directions_walk, size: 12, color: Colors.grey),
                      Text(" ${p.distanciaInfo!.caminando} ", style: const TextStyle(fontSize: 11)),
                      const Icon(Icons.directions_car, size: 12, color: Colors.grey),
                      Text(" ${p.distanciaInfo!.carro}", style: const TextStyle(fontSize: 11)),
                    ],
                  )
              ],
            ),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: p))),
          ),
        );
      },
    );
  }
}
