import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:calendario_familiar/core/models/app_user.dart';
import 'package:calendario_familiar/features/auth/data/repositories/auth_repository.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  late final AuthRepository _authRepository;
  
  @override
  AppUser? build() {
    _authRepository = AuthRepository();
    // ⚠️ COMENTADO: Desactivar la inicialización del usuario al inicio
    // Esto evita que el AuthController intente cargar un usuario y potencialmente
    // cause redirecciones o errores si la lógica de autenticación no es deseada al inicio.
    _initializeCurrentUser(); // Descomentar esta línea
    return null; // null significa "cargando", pero en este contexto solo inicializa el estado
  }
  
  Future<AppUser?> _initializeCurrentUser() async { // Cambiado de Future<void> a Future<AppUser?>
    try {
      print('🔧 _initializeCurrentUser iniciado');
      final currentUser = _authRepository.currentUser;
      print('🔧 currentUser del repositorio: $currentUser');
      
      if (currentUser != null) {
        print('🔧 Usuario encontrado, obteniendo datos completos...');
        // Obtener datos completos de Firestore
        final fullUserData = await _authRepository.getUserData(currentUser.uid);
        if (fullUserData != null) {
          print('✅ Usuario completo cargado: ${fullUserData.displayName}');
          state = fullUserData;
          return fullUserData; // Retornar el usuario completo
        } else {
          print('⚠️ Usuario básico cargado: ${currentUser.displayName}');
          state = currentUser;
          return currentUser; // Retornar el usuario básico
        }
      } else {
        print('❌ No hay usuario autenticado');
        // Establecer estado como usuario vacío (no null) para indicar "no autenticado"
        state = AppUser.empty();
        return null; // No hay usuario autenticado
      }
    } catch (e) {
      print('❌ Error inicializando usuario actual: $e');
      // En caso de error, establecer como no autenticado
      state = AppUser.empty();
      return null; // Error, no hay usuario autenticado
    }
  }
  
  Future<AppUser?> refreshCurrentUser() async { // Cambiado de Future<void> a Future<AppUser?>
    return await _initializeCurrentUser(); // Retornar el resultado de _initializeCurrentUser
  }
  
  /// Registro por correo electrónico y contraseña
  Future<AppUser?> signUpWithEmail(String email, String password, String displayName) async {
    try {
      print('🔧 Iniciando registro con email: $email');
      final user = await _authRepository.signUpWithEmail(email, password, displayName);
      if (user != null) {
        state = user;
        print('✅ Registro exitoso: ${user.displayName}');
      }
      return user;
    } catch (e) {
      print('❌ Error en signUpWithEmail: $e');
      rethrow;
    }
  }
  
  /// Inicio de sesión por correo electrónico y contraseña
  Future<AppUser?> signInWithEmail(String email, String password) async {
    try {
      print('🔧 Iniciando sesión con email: $email');
      final user = await _authRepository.signInWithEmail(email, password);
      if (user != null) {
        state = user;
        print('✅ Inicio de sesión exitoso: ${user.displayName}');
      }
      return user;
    } catch (e) {
      print('❌ Error en signInWithEmail: $e');
      rethrow;
    }
  }
  
  Future<AppUser?> signInWithGoogle() async {
    try {
      print('🔧 Iniciando Google Sign-In desde AuthController...');
      final user = await _authRepository.signInWithGoogle();
      if (user != null) {
        print('✅ Google Sign-In exitoso: ${user.displayName}');
        state = user;
        print('✅ Estado actualizado con usuario: ${user.displayName}');
        return user;
      } else {
        print('❌ Google Sign-In falló: usuario es null');
        // Verificar si hay un usuario autenticado en Firebase
        final firebaseUser = _authRepository.currentUser;
        if (firebaseUser != null) {
          print('⚠️ Usuario encontrado en Firebase, obteniendo datos completos...');
          final fullUserData = await _authRepository.getUserData(firebaseUser.uid);
          if (fullUserData != null) {
            state = fullUserData;
            print('✅ Usuario completo cargado desde Firestore: ${fullUserData.displayName}');
            return fullUserData;
          } else {
            state = firebaseUser;
            print('✅ Usuario básico cargado desde Firebase: ${firebaseUser.displayName}');
            return firebaseUser;
          }
        } else {
          state = AppUser.empty();
          return null;
        }
      }
    } catch (e) {
      // Mantener el estado actual en caso de error
      print('❌ Error en signInWithGoogle: $e');
      state = AppUser.empty();
      return null;
    }
  }
  
  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      state = null;
    } catch (e) {
      print('Error en signOut: $e');
    }
  }
  
  /// Verificar si el usuario actual tiene familia
  Future<bool> currentUserHasFamily() async {
    try {
      final currentUser = state;
      if (currentUser == null) {
        print('❌ No hay usuario autenticado');
        return false;
      }
      
      final hasFamily = await _authRepository.userHasFamily(currentUser.uid);
      print('🔍 Usuario actual tiene familia: $hasFamily');
      return hasFamily;
    } catch (e) {
      print('❌ Error verificando si usuario actual tiene familia: $e');
      return false;
    }
  }
  
  /// Obtener el rol del usuario actual en su familia
  Future<String?> getCurrentUserFamilyRole() async {
    try {
      final currentUser = state;
      if (currentUser == null) {
        print('❌ No hay usuario autenticado');
        return null;
      }
      
      final role = await _authRepository.getUserFamilyRole(currentUser.uid);
      print('🔍 Rol del usuario actual: $role');
      return role;
    } catch (e) {
      print('❌ Error obteniendo rol del usuario actual: $e');
      return null;
    }
  }
  
  Future<void> updateUserFamilyId(String? familyId) async {
    try {
      final currentUser = state;
      if (currentUser == null) {
        print('❌ No hay usuario autenticado');
        return;
      }
      
      await _authRepository.updateUserFamilyId(currentUser.uid, familyId);
      
      // Actualizar el estado local
      state = currentUser.copyWith(familyId: familyId);
      
      print('✅ FamilyId actualizado: $familyId');
    } catch (e) {
      print('Error actualizando familyId: $e');
      rethrow;
    }
  }
  
  Future<void> updateDeviceToken(String token) async {
    final currentUser = state;
    if (currentUser == null) return;
    
    try {
      await _authRepository.updateDeviceToken(currentUser.uid, token);
      final updatedTokens = List<String>.from(currentUser.deviceTokens);
      if (!updatedTokens.contains(token)) {
        updatedTokens.add(token);
      }
      final updatedUser = currentUser.copyWith(deviceTokens: updatedTokens);
      state = updatedUser;
    } catch (e) {
      print('Error actualizando device token: $e');
    }
  }
}

