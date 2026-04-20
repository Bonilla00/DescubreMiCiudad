class DistanciaInfo {
  final double distanciaKm;
  final int tiempoCarroMin;
  final int tiempoCaminandoMin;

  DistanciaInfo({
    required this.distanciaKm,
    required this.tiempoCarroMin,
    required this.tiempoCaminandoMin,
  });

  factory DistanciaInfo.fromJson(Map<String, dynamic> json) {
    return DistanciaInfo(
      distanciaKm: (json['distanciaKm'] as num).toDouble(),
      tiempoCarroMin: (json['tiempoCarroMin'] as num).toInt(),
      tiempoCaminandoMin: (json['tiempoCaminandoMin'] as num).toInt(),
    );
  }
}

class Place {
  final dynamic id; // Puede ser int (local) o String (Google)
  final String nombre;
  final String categoria;
  final String rangoPrecio;
  final String descripcion;
  final double latitud;
  final double longitud;
  final double promedioCalificacion;
  final int totalResenas;
  final String imageUrl;
  final String? direccion;
  final DistanciaInfo? distanciaInfo;
  final bool esGooglePlace;

  Place({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.rangoPrecio,
    required this.descripcion,
    required this.latitud,
    required this.longitud,
    required this.promedioCalificacion,
    required this.totalResenas,
    required this.imageUrl,
    this.direccion,
    this.distanciaInfo,
    this.esGooglePlace = false,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'],
      nombre: json['nombre'] ?? json['name'] ?? '',
      categoria: json['categoria'] ?? json['type'] ?? 'Lugar',
      rangoPrecio: json['rangoPrecio'] ?? json['price_level']?.toString() ?? 'N/A',
      descripcion: json['descripcion'] ?? '',
      latitud: (json['latitud'] ?? json['lat'] ?? json['geometry']?['location']?['lat'] ?? 0.0).toDouble(),
      longitud: (json['longitud'] ?? json['lng'] ?? json['geometry']?['location']?['lng'] ?? 0.0).toDouble(),
      promedioCalificacion: (json['promedioCalificacion'] ?? json['rating'] ?? 0.0).toDouble(),
      totalResenas: json['totalResenas'] ?? json['user_ratings_total'] ?? 0,
      imageUrl: json['imageUrl'] ?? json['imagen_url'] ?? (json['photos'] != null ? 'GOOGLE_IMAGE' : 'https://via.placeholder.com/150'),
      direccion: json['direccion'] ?? json['vicinity'],
      distanciaInfo: json['distancia_info'] != null ? DistanciaInfo.fromJson(json['distancia_info']) : null,
      esGooglePlace: json['place_id'] != null,
    );
  }
}
