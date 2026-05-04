import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // STREAM DE AUTENTICACIÓN (para mantener sesión)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // REGISTRO CON EMAIL Y PASSWORD
  Future<Map<String, dynamic>> register(String nombre, String email, String password) async {
    try {
      // Validaciones
      if (email.isEmpty || !email.contains('@')) {
        return {'success': false, 'error': 'Correo electrónico inválido'};
      }
      if (password.length < 6) {
        return {'success': false, 'error': 'La contraseña debe tener al menos 6 caracteres'};
      }
      if (nombre.isEmpty) {
        return {'success': false, 'error': 'El nombre es requerido'};
      }

      // Crear usuario en Firebase
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Actualizar nombre en Firebase
      await userCredential.user?.updateDisplayName(nombre);

      // Guardar en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nombre', nombre);
      await prefs.setInt('userId', userCredential.user!.uid.hashCode);

      return {
        'success': true,
        'userId': userCredential.user!.uid,
        'nombre': nombre
      };
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return {'success': false, 'error': 'Error inesperado: $e'};
    }
  }

  // INICIO DE SESIÓN CON EMAIL Y PASSWORD
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      if (email.isEmpty || !email.contains('@')) {
        return {'success': false, 'error': 'Correo electrónico inválido'};
      }
      if (password.isEmpty) {
        return {'success': false, 'error': 'La contraseña es requerida'};
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Guardar datos de sesión
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nombre', userCredential.user?.displayName ?? 'Usuario');
      await prefs.setInt('userId', userCredential.user!.uid.hashCode);

      return {
        'success': true,
        'nombre': userCredential.user?.displayName ?? 'Usuario',
        'userId': userCredential.user!.uid
      };
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // CERRAR SESIÓN
  Future<void> logout() async {
    try {
      await _auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error logout: $e');
    }
  }

  // VERIFICAR SI ESTÁ LOGUEADO
  Future<bool> isLoggedIn() async {
    User? user = _auth.currentUser;
    return user != null;
  }

  // OBTENER USUARIO ACTUAL
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  // OBTENER NOMBRE
  Future<String?> getToken() async {
    final user = _auth.currentUser;
    return await user?.getIdToken();
  }

  Future<String?> getNombre() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return user.displayName ?? user.email?.split('@')[0];
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nombre');
  }

  Future<int?> getUserId() async {
    User? user = _auth.currentUser;
    return user?.uid.hashCode;
  }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nombre');
  }

  // OBTENER USER ID
  Future<String?> getUserId() async {
    User? user = _auth.currentUser;
    return user?.uid;
  }

  // OBTENER EMAIL
  Future<String?> getEmail() async {
    User? user = _auth.currentUser;
    return user?.email;
  }

  // OBTENER URL FOTO PERFIL
  Future<String?> getPhotoURL() async {
    User? user = _auth.currentUser;
    return user?.photoURL;
  }

  // ENVIAR CORREO DE VERIFICACIÓN
  Future<bool> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return true;
      }
      return false;
    } catch (e) {
      print('Error sending verification: $e');
      return false;
    }
  }

  // RECARGAR USUARIO (para verificar email verificado)
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // MANEJO DE ERRORES DE FIREBASE
  Map<String, dynamic> _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
        return {'success': false, 'error': 'Credenciales incorrectas'};
      case 'email-already-in-use':
        return {'success': false, 'error': 'El correo ya está registrado'};
      case 'invalid-email':
        return {'success': false, 'error': 'Correo electrónico inválido'};
      case 'weak-password':
        return {'success': false, 'error': 'Contraseña muy débil (mínimo 6 caracteres)'};
      case 'operation-not-allowed':
        return {'success': false, 'error': 'Operación no permitida'};
      case 'user-disabled':
        return {'success': false, 'error': 'Usuario deshabilitado'};
      case 'too-many-requests':
        return {'success': false, 'error': 'Demasiados intentos. Intenta más tarde'};
      case 'network-request-failed':
        return {'success': false, 'error': 'Error de conexión. Verifica tu internet'};
      case 'account-exists-with-different-credential':
        return {'success': false, 'error': 'Ya existe una cuenta con este email usando otro método'};
      default:
        return {'success': false, 'error': 'Error: ${e.message}'};
    }
  }

  // CAMBIAR CONTRASEÑA
  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'No hay sesión activa'};
      }

      // Reautenticar
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      
      return {'success': true, 'message': 'Contraseña actualizada'};
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  // ELIMINAR CUENTA
  Future<Map<String, dynamic>> deleteAccount(String password) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'No hay sesión activa'};
      }

      // Reautenticar
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      
      await user.reauthenticateWithCredential(credential);
      await user.delete();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      return {'success': true, 'message': 'Cuenta eliminada'};
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }
}
