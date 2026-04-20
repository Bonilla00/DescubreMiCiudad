import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/place_model.dart';
import '../services/lugares_service.dart';
import 'place_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LugaresService _lugaresService = LugaresService();
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  List<Place> _lugares = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _currentPosition = await Geolocator.getCurrentPosition();
    _loadLugares();
  }

  void _loadLugares() async {
    final data = await _lugaresService.getLugares();
    if (mounted) {
      setState(() {
        _lugares = data.map((item) => Place.fromJson(item)).toList();
        _createMarkers();
        _isLoading = false;
      });
    }
  }

  void _createMarkers() {
    final markers = _lugares.map((place) {
      return Marker(
        markerId: MarkerId(place.id.toString()),
        position: LatLng(place.lat, place.lng),
        infoWindow: InfoWindow(
          title: place.nombre,
          snippet: "${place.categoria} - ${place.rating} ⭐",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PlaceDetailScreen(place: place)),
            );
          },
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          place.categoria == 'Restaurante' ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure,
        ),
      );
    }).toSet();

    setState(() => _markers = markers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_currentPosition?.latitude ?? 3.4516, _currentPosition?.longitude ?? -76.5320),
                    zoom: 14,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _lugares.length,
                      itemBuilder: (context, index) {
                        final place = _lugares[index];
                        return GestureDetector(
                          onTap: () {
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLng(LatLng(place.lat, place.lng)),
                            );
                          },
                          child: Container(
                            width: 250,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                                  child: CachedNetworkImage(
                                    imageUrl: place.imagenUrl,
                                    width: 80,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: Colors.grey[200]),
                                    errorWidget: (context, url, error) => const Icon(Icons.image_not_supported),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(place.nombre, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                                        Text("${place.categoria} • ${place.rating} ⭐", style: const TextStyle(fontSize: 12)),
                                        Text(place.distancia, style: const TextStyle(fontSize: 11, color: Colors.blue)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
