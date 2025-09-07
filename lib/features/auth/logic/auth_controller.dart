import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:calendario_familiar/core/models/app_user.dart';
import 'package:calendario_familiar/features/auth/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importar FirebaseAuth para acceder al usuario actual

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  late final AuthRepository _authRepository;
  
  @override
  AppUser? build() {
    _authRepository = AuthRepository();
    // Inicializar el usuario actual al construir el controlador
    _initializeCurrentUser();
    return null; // null significa "cargando"
  }
  
  Future<AppUser?> _initializeCurrentUser() async {
    try {
      print('🔧 _initializeCurrentUser iniciado');
      // Obtener el usuario actual de Firebase Authentication directamente
      final firebaseAuthUser = FirebaseAuth.instance.currentUser;
      print('🔧 FirebaseAuth.instance.currentUser: ${firebaseAuthUser?.uid ?? 'null'}');

      if (firebaseAuthUser != null) {
        print('🔧 Usuario Firebase encontrado (${firebaseAuthUser.uid}), obteniendo datos completos de Firestore...');
        // Forzar la obtención de los datos más recientes del AppUser desde Firestore
        final fullUserData = await _authRepository.getUserData(firebaseAuthUser.uid);
        
        if (fullUserData != null) {
          print('✅ Usuario completo cargado de Firestore: ${fullUserData.displayName}, FamilyId: ${fullUserData.familyId}');
          state = fullUserData;
          return fullUserData;
        } else {
          // Si no hay datos completos en Firestore, crear un AppUser básico
          final basicUser = AppUser(
            uid: firebaseAuthUser.uid,
            email: firebaseAuthUser.email ?? '',
            displayName: firebaseAuthUser.displayName ?? '',
            photoUrl: firebaseAuthUser.photoURL,
            familyId: null, // Asegurarse de que si no hay familyId en Firestore, se refleje aquí
            deviceTokens: [],
          );
          print('⚠️ Usuario básico creado (no datos completos en Firestore): ${basicUser.displayName}, FamilyId: ${basicUser.familyId}');
          state = basicUser;
          return basicUser;
        }
      } else {
        print('❌ No hay usuario autenticado en Firebase');
        state = AppUser.empty();
        return null;
      }
    } catch (e) {
      print('❌ Error inicializando usuario actual: $e');
      state = AppUser.empty();
      return null;
    }
  }
  
  Future<AppUser?> refreshCurrentUser() async {
    print('🔄 refreshCurrentUser llamado, forzando una nueva inicialización...');
    // Reutilizar _initializeCurrentUser para asegurar una carga fresca desde Firebase Auth y Firestore
    return await _initializeCurrentUser(); 
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
      print('🔧 updateUserFamilyId iniciado. Usuario actual en estado: ${currentUser?.uid ?? 'null'}, FamilyId actual en estado: ${currentUser?.familyId ?? 'null'}');

      if (currentUser == null) {
        print('❌ updateUserFamilyId: No hay usuario autenticado en el estado. No se puede actualizar familyId.');
        return;
      }
      
      print('🔧 Actualizando familyId en Firestore para ${currentUser.uid} a: ${familyId ?? 'null'}');
      await _authRepository.updateUserFamilyId(currentUser.uid, familyId);
      
      // Actualizar el estado local
      final updatedUserState = currentUser.copyWith(familyId: familyId);
      state = updatedUserState;
      
      print('✅ FamilyId actualizado en estado del controlador: ${state?.familyId ?? 'null'}');
      print('✅ Usuario en estado después de la actualización de familyId: $state');
      
    } catch (e) {
      print('❌ Error en updateUserFamilyId: $e');
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

