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
    // Inicializar con el usuario actual si ya está autenticado
    _initializeCurrentUser();
    return null; // null significa "cargando"
  }
  
  Future<void> _initializeCurrentUser() async {
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
        } else {
          print('⚠️ Usuario básico cargado: ${currentUser.displayName}');
          state = currentUser;
        }
      } else {
        print('❌ No hay usuario autenticado');
        // Establecer estado como usuario vacío (no null) para indicar "no autenticado"
        state = AppUser.empty();
      }
    } catch (e) {
      print('❌ Error inicializando usuario actual: $e');
      // En caso de error, establecer como no autenticado
      state = AppUser.empty();
    }
  }
  
  Future<void> refreshCurrentUser() async {
    await _initializeCurrentUser();
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
  
  Future<void> signInWithGoogle() async {
    try {
      print('🔧 Iniciando Google Sign-In desde AuthController...');
      final user = await _authRepository.signInWithGoogle();
      if (user != null) {
        state = user;
        print('✅ Google Sign-In exitoso: ${user.displayName}');
      } else {
        print('❌ Google Sign-In falló: usuario es null');
        state = AppUser.empty();
      }
    } catch (e) {
      // Mantener el estado actual en caso de error
      print('❌ Error en signInWithGoogle: $e');
      state = AppUser.empty();
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

