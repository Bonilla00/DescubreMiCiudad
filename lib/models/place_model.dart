class DistanciaInfo {
  final double distanciaKm;
  final String distanciaTexto;
  final String carro;
  final String caminando;

  DistanciaInfo({
    required this.distanciaKm,
    required this.distanciaTexto,
    required this.carro,
    required this.caminando,
  });

  factory DistanciaInfo.fromJson(Map<String, dynamic> json) {
    return DistanciaInfo(
      distanciaKm: double.tryParse(json['distancia_km'].toString()) ?? 0.0,
      distanciaTexto: json['distancia_texto'] ?? '',
      carro: json['carro'] ?? '',
      caminando: json['caminando'] ?? '',
    );
  }
}

class Place {
  final dynamic id; // Puede ser int para locales o String para Google
  final String nombre;
  final String categoria;
  final String precio;
  final String priceLevel;
  final double rating;
  final String distancia;
  final String descripcion;
  final String imagenUrl;
  final double lat;
  final double lng;
  final DistanciaInfo? distanciaInfo;
  final bool esGoogle;

  Place({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.priceLevel,
    required this.rating,
    required this.distancia,
    required this.descripcion,
    required this.imagenUrl,
    required this.lat,
    required this.lng,
    this.distanciaInfo,
    this.esGoogle = false,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      categoria: json['categoria'] ?? '',
      precio: json['precio'] ?? '',
      priceLevel: json['price_level'] ?? '',
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      distancia: json['distancia'] ?? '',
      descripcion: json['descripcion'] ?? '',
      imagenUrl: json['imagen_url'] ?? '',
      lat: double.tryParse(json['lat'].toString()) ?? 0.0,
      lng: double.tryParse(json['lng'].toString()) ?? 0.0,
      distanciaInfo: json['distancia_info'] != null ? DistanciaInfo.fromJson(json['distancia_info']) : null,
      esGoogle: json['esGoogle'] ?? false,
    );
  }
}
