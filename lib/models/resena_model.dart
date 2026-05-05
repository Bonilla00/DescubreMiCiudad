class Resena {
  final String usuario;
  final String comentario;
  final int rating;
  final String fecha;

  Resena({
    required this.usuario,
    required this.comentario,
    required this.rating,
    required this.fecha,
  });

  factory Resena.fromJson(Map<String, dynamic> json) {
    return Resena(
      usuario: json['usuario'] ?? 'Usuario',
      comentario: json['comentario'] ?? '',
      rating: json['rating'] ?? 5,
      fecha: json['fecha'] ?? DateTime.now().toIso8601String(),
    );
  }
}
