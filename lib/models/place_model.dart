class Place {
  final int id;
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
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'],
      nombre: json['nombre'],
      categoria: json['categoria'],
      precio: json['precio'],
      priceLevel: json['price_level'] ?? '',
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      distancia: json['distancia'],
      descripcion: json['descripcion'],
      imagenUrl: json['imagen_url'],
      lat: double.tryParse(json['lat'].toString()) ?? 0.0,
      lng: double.tryParse(json['lng'].toString()) ?? 0.0,
    );
  }
}
