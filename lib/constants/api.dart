class ApiConstants {
  // Ajustado a la URL real de tu captura de Railway (produccion en español)
  static const String baseUrl = 'https://descubremiciudad-produccion.up.railway.app';
  
  static const String login = '$baseUrl/api/auth/login';
  static const String register = '$baseUrl/api/auth/register';
  
  // Corregido: El backend usa /api/usuarios para el perfil
  static const String profile = '$baseUrl/api/usuarios/perfil';
  static const String profileUpdate = '$baseUrl/api/usuarios/perfil';
  static const String statistics = '$baseUrl/api/usuarios/estadisticas';
  
  static const String places = '$baseUrl/api/lugares';
  static const String reviews = '$baseUrl/api/resenas';
  static const String favorites = '$baseUrl/api/favoritos';
  
  // Tiempos de espera aumentados para el servidor gratuito
  static const Duration timeout = Duration(seconds: 20);
}
