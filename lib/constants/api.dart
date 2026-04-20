class ApiConstants {
  static const String baseUrl = 'https://descubremiciudad-production.up.railway.app';
  static const String login = '$baseUrl/api/auth/login';
  static const String register = '$baseUrl/api/auth/register';
  static const String profile = '$baseUrl/api/auth/perfil';
  static const String profileUpdate = '$baseUrl/api/auth/perfil/update';
  static const String places = '$baseUrl/api/lugares';
  static const String reviews = '$baseUrl/api/resenas';
  static const String favorites = '$baseUrl/api/favoritos';
  
  // Tiempos de espera para mejorar la experiencia con el servidor gratuito
  static const Duration timeout = Duration(seconds: 15);
}
