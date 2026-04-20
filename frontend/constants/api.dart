class ApiConstants {
  // Dirección base corregida para tu servidor Railway (production en inglés)
  static const String baseUrl = 'https://descubremiciudad-production.up.railway.app';
  static const String apiBaseUrl = '$baseUrl/api';
  
  static const String login = '$apiBaseUrl/auth/login';
  static const String register = '$apiBaseUrl/auth/register';
  
  // Rutas de usuario
  static const String profile = '$apiBaseUrl/usuarios/perfil';
  static const String profileUpdate = '$apiBaseUrl/usuarios/perfil';
  
  static const String places = '$apiBaseUrl/lugares';
  static const String reviews = '$apiBaseUrl/resenas';
  static const String favorites = '$apiBaseUrl/favoritos';
  
  static const Duration timeout = Duration(seconds: 20);
}
