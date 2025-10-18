import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:calendario_familiar/core/models/local_user.dart';

/// Servicio para sincronizar usuarios locales con Firebase
class UserSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'local_users';

  /// 🔹 Inicializar usuarios en Firebase (solo si no existen)
  static Future<void> initializeUsersInFirebase() async {
    try {
      print('🔄 Inicializando usuarios en Firebase...');

      // Verificar si ya existen usuarios en Firebase
      final snapshot = await _firestore.collection(_collectionName).get();
      
      if (snapshot.docs.isEmpty) {
        print('📝 No hay usuarios en Firebase, creando usuarios por defecto...');
        
        // Crear usuarios por defecto en Firebase
        for (final user in localUsers) {
          await _firestore
              .collection(_collectionName)
              .doc('user_${user.id}')
              .set(user.toJson());
          
          print('✅ Usuario creado en Firebase: ${user.name} (ID: ${user.id})');
        }
        
        print('🎉 Usuarios inicializados en Firebase correctamente');
      } else {
        print('✅ Usuarios ya existen en Firebase: ${snapshot.docs.length} usuarios');
      }
    } catch (e) {
      print('❌ Error inicializando usuarios en Firebase: $e');
    }
  }

  /// 🔹 Cargar usuarios desde Firebase
  static Future<void> loadUsersFromFirebase() async {
    try {
      print('🔄 Cargando usuarios desde Firebase...');

      final snapshot = await _firestore.collection(_collectionName).get();
      
      if (snapshot.docs.isNotEmpty) {
        // Limpiar lista local
        localUsers.clear();
        
        // Cargar usuarios desde Firebase
        for (final doc in snapshot.docs) {
          final user = LocalUser.fromJson(doc.data());
          localUsers.add(user);
          print('📝 Usuario cargado: ${user.name} (ID: ${user.id}, Color: ${user.color})');
        }
        
        // Ordenar por ID
        localUsers.sort((a, b) => a.id.compareTo(b.id));
        
        print('✅ Usuarios cargados desde Firebase: ${localUsers.length} usuarios');
      } else {
        print('⚠️ No hay usuarios en Firebase, usando usuarios por defecto');
      }
    } catch (e) {
      print('❌ Error cargando usuarios desde Firebase: $e');
    }
  }

  /// 🔹 Actualizar un usuario en Firebase
  static Future<void> updateUserInFirebase(LocalUser user) async {
    try {
      print('🔄 Actualizando usuario en Firebase: ${user.name} (ID: ${user.id})');

      await _firestore
          .collection(_collectionName)
          .doc('user_${user.id}')
          .update(user.toJson());
      
      print('✅ Usuario actualizado en Firebase: ${user.name}');
    } catch (e) {
      print('❌ Error actualizando usuario en Firebase: $e');
    }
  }

  /// 🔹 Escuchar cambios en usuarios desde Firebase
  static Stream<List<LocalUser>> listenToUsers() {
    return _firestore
        .collection(_collectionName)
        .snapshots()
        .map((snapshot) {
      final users = <LocalUser>[];
      
      for (final doc in snapshot.docs) {
        try {
          final user = LocalUser.fromJson(doc.data());
          users.add(user);
        } catch (e) {
          print('❌ Error parseando usuario ${doc.id}: $e');
        }
      }
      
      // Ordenar por ID
      users.sort((a, b) => a.id.compareTo(b.id));
      
      return users;
    });
  }

  /// 🔹 Sincronizar lista local con Firebase
  static Future<void> syncLocalUsersWithFirebase() async {
    try {
      print('🔄 Sincronizando usuarios locales con Firebase...');

      // Actualizar cada usuario local en Firebase
      for (final user in localUsers) {
        await _firestore
            .collection(_collectionName)
            .doc('user_${user.id}')
            .set(user.toJson(), SetOptions(merge: true));
      }
      
      print('✅ Usuarios locales sincronizados con Firebase');
    } catch (e) {
      print('❌ Error sincronizando usuarios con Firebase: $e');
    }
  }
}

