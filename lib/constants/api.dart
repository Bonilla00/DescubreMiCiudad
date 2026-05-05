class ApiConstants {
  // URL base actualizada según requerimiento
  static const String baseUrl = 'https://descubremiciudad-production.up.railway.app';
  
  static const String login = '$baseUrl/api/auth/login';
  static const String register = '$baseUrl/api/auth/register';
  
  static const String profile = '$baseUrl/api/usuarios/perfil';
  
  // Endpoint directo /lugares solicitado
  static const String places = '$baseUrl/lugares';
  static const String reviews = '$baseUrl/api/resenas';
  static const String favorites = '$baseUrl/api/favoritos';
  
  static const Duration timeout = Duration(seconds: 20);
}
