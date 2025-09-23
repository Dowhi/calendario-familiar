import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:calendario_familiar/core/models/app_user.dart';
import 'package:calendario_familiar/features/auth/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'auth_controller_temp.g.dart';

@riverpod
class AuthControllerTemp extends _$AuthControllerTemp {
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
            familyId: null,
            deviceTokens: [],
          );
          print('⚠️ Usuario básico creado (no datos completos en Firestore): ${basicUser.displayName}, FamilyId: ${basicUser.familyId}');
          state = basicUser;
          return basicUser;
        }
      } else {
        print('🔧 No hay usuario autenticado en Firebase');
        state = AppUser.empty();
        return null;
      }
    } catch (e) {
      print('❌ Error en _initializeCurrentUser: $e');
      state = AppUser.empty();
      return null;
    }
  }

  /// Inicia sesión con email y contraseña
  Future<AppUser?> signInWithEmail(String email, String password) async {
    try {
      print('🔐 Iniciando sesión con email: $email');
      final user = await _authRepository.signInWithEmail(email, password);
      if (user != null) {
        print('✅ Sesión iniciada exitosamente: ${user.displayName}');
        state = user;
      }
      return user;
    } catch (e) {
      print('❌ Error en signInWithEmail: $e');
      return null;
    }
  }

  /// Registra un nuevo usuario con email y contraseña
  Future<AppUser?> signUpWithEmail(String email, String password, String displayName) async {
    try {
      print('📝 Registrando nuevo usuario: $email');
      final user = await _authRepository.signUpWithEmail(email, password, displayName);
      if (user != null) {
        print('✅ Usuario registrado exitosamente: ${user.displayName}');
        state = user;
      }
      return user;
    } catch (e) {
      print('❌ Error en signUpWithEmail: $e');
      return null;
    }
  }

  /// Google Sign-In DESHABILITADO temporalmente
  Future<AppUser?> signInWithGoogle() async {
    try {
      print('⚠️ Google Sign-In temporalmente deshabilitado para testing');
      showGlobalSnackBar('Google Sign-In temporalmente deshabilitado. Usa email/contraseña.');
      return null;
    } catch (e) {
      print('❌ Error en signInWithGoogle: $e');
      return null;
    }
  }

  /// Cierra sesión
  Future<void> signOut() async {
    try {
      print('🚪 Cerrando sesión...');
      await _authRepository.signOut();
      state = AppUser.empty();
      print('✅ Sesión cerrada exitosamente');
    } catch (e) {
      print('❌ Error en signOut: $e');
    }
  }

  /// Actualiza el familyId del usuario actual
  Future<void> updateUserFamilyId(String? familyId) async {
    try {
      final currentUser = state;
      if (currentUser == null) {
        print('❌ No hay usuario actual para actualizar familyId');
        return;
      }

      print('🔄 Actualizando familyId para usuario ${currentUser.uid}: $familyId');
      
      // Actualizar en Firestore
      await _authRepository.updateUserFamilyId(currentUser.uid, familyId);
      
      // Actualizar el estado local
      final updatedUserState = currentUser.copyWith(familyId: familyId);
      state = updatedUserState;
      
      print('✅ FamilyId actualizado en estado del controlador: ${state?.familyId ?? 'null'}');
      print('✅ Usuario en estado después de la actualización de familyId: $state');
    } catch (e) {
      print('❌ Error actualizando familyId: $e');
    }
  }

  /// Actualiza los datos del usuario
  Future<void> updateUser(AppUser updatedUser) async {
    try {
      final currentUser = state;
      if (currentUser == null) {
        print('❌ No hay usuario actual para actualizar');
        return;
      }

      print('🔄 Actualizando datos del usuario: ${updatedUser.uid}');
      
      // Actualizar en Firestore
      // await _authRepository.updateUser(updatedUser); // Temporalmente deshabilitado
      
      // Actualizar el estado local
      state = updatedUser;
      
      print('✅ Usuario actualizado exitosamente');
    } catch (e) {
      print('❌ Error actualizando usuario: $e');
    }
  }

  /// Verifica si el usuario actual tiene una familia
  Future<bool> currentUserHasFamily() async {
    final currentUser = state;
    return currentUser?.familyId != null && currentUser!.familyId!.isNotEmpty;
  }

  /// Refresca el usuario actual
  Future<AppUser?> refreshCurrentUser() async {
    return await _initializeCurrentUser();
  }
}

// Función global para mostrar snackbar (temporal)
void showGlobalSnackBar(String message, {Color? backgroundColor}) {
  // Implementación temporal - se puede mejorar
  print('📱 SnackBar: $message');
}
