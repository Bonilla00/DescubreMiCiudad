class Resena {
  final int id;
  final String usuario;
  final String avatar;
  final String comentario;
  final int rating;
  final String fecha;
  final String lugarNombre;

  Resena({
    required this.id,
    required this.usuario,
    required this.avatar,
    required this.comentario,
    required this.rating,
    required this.fecha,
    this.lugarNombre = '',
  });

  factory Resena.fromJson(Map<String, dynamic> json) {
    return Resena(
      id: json['id'] ?? 0,
      usuario: json['usuario'] ?? 'Usuario',
      avatar: json['avatar'] ?? 'https://i.pravatar.cc/150',
      comentario: json['comentario'] ?? '',
      rating: json['rating'] ?? 5,
      fecha: json['fecha'] ?? json['creado_en'] ?? '',
      lugarNombre: json['lugar_nombre'] ?? '',
    );
  }
}
