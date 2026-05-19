class Place {
  final String id;
  final String nombre;
  final String categoria;
  final double rating;
  final String descripcion;
  final String imagenUrl;
  final double lat;
  final double lng;

  Place({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.rating,
    required this.descripcion,
    required this.imagenUrl,
    required this.lat,
    required this.lng,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      categoria: json['categoria'] ?? '',
      rating: double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0,
      descripcion: json['descripcion'] ?? '',
      imagenUrl: json['imagen'] ?? '',
      lat: double.tryParse(json['latitud']?.toString() ?? json['lat']?.toString() ?? '0.0') ?? 0.0,
      lng: double.tryParse(json['longitud']?.toString() ?? json['lng']?.toString() ?? '0.0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'rating': rating,
      'descripcion': descripcion,
      'imagen': imagenUrl,
      'latitud': lat,
      'longitud': lng,
    };
  }
}
