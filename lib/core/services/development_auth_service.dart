import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio de autenticación automática para desarrollo
/// Este servicio crea automáticamente un usuario de prueba para desarrollo
class DevelopmentAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Inicializar autenticación automática para desarrollo
  static Future<void> initializeDevelopmentAuth() async {
    try {
      print('🔐 Inicializando autenticación de desarrollo...');
      
      // Verificar si ya hay un usuario autenticado
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('✅ Usuario ya autenticado: ${currentUser.email}');
        return;
      }

      // Intentar autenticación anónima para desarrollo
      final UserCredential userCredential = await _auth.signInAnonymously();
      print('✅ Usuario anónimo creado: ${userCredential.user?.uid}');
      
      // Crear datos de usuario básicos en Firestore
      await _createUserProfile(userCredential.user!);
      
    } catch (e) {
      print('❌ Error en autenticación de desarrollo: $e');
      
      // Si falla la autenticación anónima, intentar con Google
      try {
        await _signInWithGoogle();
      } catch (googleError) {
        print('❌ Error en autenticación con Google: $googleError');
        // Continuar sin autenticación - las reglas temporales permitirán acceso
      }
    }
  }

  /// Autenticación con Google como fallback
  static Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      print('✅ Usuario Google autenticado: ${userCredential.user?.email}');
      
      await _createUserProfile(userCredential.user!);
    } catch (e) {
      print('❌ Error en autenticación con Google: $e');
      rethrow;
    }
  }

  /// Crear perfil de usuario en Firestore
  static Future<void> _createUserProfile(User user) async {
    try {
      // Crear perfil básico del usuario
      final userData = {
        'uid': user.uid,
        'email': user.email ?? 'usuario@desarrollo.com',
        'displayName': user.displayName ?? 'Usuario Desarrollo',
        'photoURL': user.photoURL,
        'createdAt': DateTime.now().toIso8601String(),
        'isDevelopmentUser': true,
      };

      // Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));
      
      print('✅ Perfil de usuario creado en Firestore');
    } catch (e) {
      print('❌ Error creando perfil de usuario: $e');
    }
  }

  /// Obtener usuario actual
  static User? getCurrentUser() => _auth.currentUser;

  /// Verificar si hay usuario autenticado
  static bool isAuthenticated() => _auth.currentUser != null;

  /// Cerrar sesión
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      print('✅ Sesión cerrada');
    } catch (e) {
      print('❌ Error cerrando sesión: $e');
    }
  }
}
