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
      distanciaKm: (json['distancia_km'] ?? json['distanciaKm'] ?? 0.0).toDouble(),
      tiempoCarroMin: (json['tiempo_carro_min'] ?? json['tiempoCarroMin'] ?? 0).toInt(),
      tiempoCaminandoMin: (json['tiempo_caminando_min'] ?? json['tiempoCaminandoMin'] ?? 0).toInt(),
    );
  }
}

class Place {
  final dynamic id; 
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
      nombre: json['nombre'] ?? json['name'] ?? 'Restaurante Cali',
      categoria: json['categoria'] ?? json['type'] ?? 'Lugar',
      rangoPrecio: json['rangoPrecio'] ?? json['price_level']?.toString() ?? '\$\$',
      descripcion: json['descripcion'] ?? 'Sin descripción disponible',
      latitud: (json['latitud'] ?? json['lat'] ?? 0.0).toDouble(),
      longitud: (json['longitud'] ?? json['lng'] ?? 0.0).toDouble(),
      promedioCalificacion: (json['promedioCalificacion'] ?? json['rating'] ?? 4.0).toDouble(),
      totalResenas: json['totalResenas'] ?? json['user_ratings_total'] ?? 0,
      imageUrl: json['imageUrl'] ?? json['imagen_url'] ?? 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
      direccion: json['direccion'] ?? json['vicinity'],
      distanciaInfo: json['distancia_info'] != null ? DistanciaInfo.fromJson(json['distancia_info']) : null,
      esGooglePlace: json['esGoogle'] ?? false,
    );
  }
}
