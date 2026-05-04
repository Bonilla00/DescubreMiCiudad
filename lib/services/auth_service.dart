import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyLoggedIn = 'is_logged_in';
  static const String _keyEmail = 'user_email';
  static const String _keyNombre = 'user_nombre';
  static const String _keyUserId = 'user_id';

  // Verificar si hay sesión activa
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  // Registro de usuario (simulado - guarda en SharedPreferences)
  Future<Map<String, dynamic>> register(String nombre, String email, String password) async {
    try {
      if (email.isEmpty || !email.contains('@')) {
        return {'success': false, 'error': 'Correo electrónico inválido'};
      }
      if (password.length < 6) {
        return {'success': false, 'error': 'La contraseña debe tener al menos 6 caracteres'};
      }
      if (nombre.isEmpty) {
        return {'success': false, 'error': 'El nombre es requerido'};
      }

      // Simular registro - guardar en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = DateTime.now().millisecondsSinceEpoch;
      
      await prefs.setBool(_keyLoggedIn, true);
      await prefs.setString(_keyEmail, email);
      await prefs.setString(_keyNombre, nombre);
      await prefs.setInt(_keyUserId, userId);

      return {
        'success': true,
        'userId': userId,
        'nombre': nombre
      };
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  // Login de usuario (simulado)
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      if (email.isEmpty || !email.contains('@')) {
        return {'success': false, 'error': 'Correo electrónico inválido'};
      }
      if (password.isEmpty) {
        return {'success': false, 'error': 'La contraseña es requerida'};
      }

      // En un sistema real, aquí se verificaría contra una base de datos
      // Por ahora, simulamos que cualquier credencial es válida
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString(_keyEmail);
      
      // Si hay un usuario registrado con ese email, permitir login
      if (savedEmail != null && savedEmail == email) {
        await prefs.setBool(_keyLoggedIn, true);
        return {
          'success': true,
          'nombre': prefs.getString(_keyNombre) ?? 'Usuario',
          'userId': prefs.getInt(_keyUserId) ?? 0
        };
      } else {
        // Si no hay usuario registrado, permitir login simulado
        await prefs.setBool(_keyLoggedIn, true);
        await prefs.setString(_keyEmail, email);
        await prefs.setString(_keyNombre, email.split('@')[0]);
        await prefs.setInt(_keyUserId, DateTime.now().millisecondsSinceEpoch);
        
        return {
          'success': true,
          'nombre': email.split('@')[0],
          'userId': DateTime.now().millisecondsSinceEpoch
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
  }

  // Obtener usuario actual
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    
    if (!isLoggedIn) return null;
    
    return {
      'email': prefs.getString(_keyEmail),
      'nombre': prefs.getString(_keyNombre),
      'userId': prefs.getInt(_keyUserId),
    };
  }

  // Obtener nombre
  Future<String?> getNombre() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyNombre);
  }

  // Obtener email
  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  // Obtener user ID
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  // Obtener token (simulado - no hay token real)
  Future<String?> getToken() async {
    // Retornar null ya que no hay auth real con tokens
    return null;
  }
}
