class Lugar {
  final int id;
  final String nombre;
  final String categoria;
  final String rangoPrecio;
  final String descripcion;
  final double latitud;
  final double longitud;
  final double promedioCalificacion;
  final int totalResenas;
  final String imageUrl;

  Lugar({
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
  });

  factory Lugar.fromJson(Map<String, dynamic> json) {
    return Lugar(
      id: json['id'],
      nombre: json['nombre'],
      categoria: json['categoria'],
      rangoPrecio: json['rangoPrecio'],
      descripcion: json['descripcion'] ?? '',
      latitud: json['latitud']?.toDouble() ?? 0.0,
      longitud: json['longitud']?.toDouble() ?? 0.0,
      promedioCalificacion: json['promedioCalificacion']?.toDouble() ?? 0.0,
      totalResenas: json['totalResenas'] ?? 0,
      imageUrl: json['imageUrl'] ?? 'https://via.placeholder.com/150',
    );
  }
}
