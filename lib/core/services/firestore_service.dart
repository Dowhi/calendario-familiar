import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calendario_familiar/core/models/family.dart' as family_model; // Usar alias
import 'dart:math';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Colecciones
  static const String _eventsCollection = 'events';
  static const String _categoriesCollection = 'categories';
  static const String _familiesCollection = 'families';
  static const String _usersCollection = 'users';
  static const String _shiftTemplatesCollection = 'shift_templates';

  // Convertir Timestamp a DateTime
  DateTime _timestampToDateTime(Timestamp timestamp) {
    return timestamp.toDate();
  }

  // Convertir DateTime a Timestamp
  Timestamp _dateTimeToTimestamp(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }

  // Obtener el ID del usuario actual
  String? get _currentUserId => _auth.currentUser?.uid;

  // ===== EVENTOS =====

  // Agregar evento
  Future<void> addEvent({
    required String title,
    required DateTime date,
    String? description,
    String? category,
    String? color,
    String? familyId,
  }) async {
    try {
      final eventData = {
        'title': title,
        'date': _dateTimeToTimestamp(date),
        'description': description ?? '',
        'category': category ?? '',
        'color': color ?? '',
        'familyId': familyId ?? _currentUserId,
        'userId': _currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(_eventsCollection).add(eventData);
      notifyListeners();
    } catch (e) {
      print('Error agregando evento: $e');
      rethrow;
    }
  }

  // Actualizar evento
  Future<void> updateEvent({
    required String eventId,
    String? title,
    DateTime? date,
    String? description,
    String? category,
    String? color,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updateData['title'] = title;
      if (date != null) updateData['date'] = _dateTimeToTimestamp(date);
      if (description != null) updateData['description'] = description;
      if (category != null) updateData['category'] = category;
      if (color != null) updateData['color'] = color;

      await _firestore.collection(_eventsCollection).doc(eventId).update(updateData);
      notifyListeners();
    } catch (e) {
      print('Error actualizando evento: $e');
      rethrow;
    }
  }

  // Eliminar evento
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection(_eventsCollection).doc(eventId).delete();
      notifyListeners();
    } catch (e) {
      print('Error eliminando evento: $e');
      rethrow;
    }
  }

  // Obtener eventos por mes
  Stream<List<Map<String, dynamic>>> getEventsByMonth(DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return _firestore
        .collection(_eventsCollection)
        .where('date', isGreaterThanOrEqualTo: _dateTimeToTimestamp(startOfMonth))
        .where('date', isLessThanOrEqualTo: _dateTimeToTimestamp(endOfMonth))
        .where('familyId', isEqualTo: _currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'date': _timestampToDateTime(data['date']),
          'description': data['description'] ?? '',
          'category': data['category'] ?? '',
          'color': data['color'] ?? '',
        };
      }).toList();
    });
  }

  // Obtener eventos por día
  Future<List<Map<String, dynamic>>> getEventsByDay(DateTime day) async {
    try {
      final startOfDay = DateTime(day.year, day.month, day.day);
      final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection(_eventsCollection)
          .where('date', isGreaterThanOrEqualTo: _dateTimeToTimestamp(startOfDay))
          .where('date', isLessThanOrEqualTo: _dateTimeToTimestamp(endOfDay))
          .where('familyId', isEqualTo: _currentUserId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'date': _timestampToDateTime(data['date']),
          'description': data['description'] ?? '',
          'category': data['category'] ?? '',
          'color': data['color'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error obteniendo eventos del día: $e');
      return [];
    }
  }

  // ===== CATEGORÍAS =====

  // Agregar categoría
  Future<void> addCategory({
    required String name,
    required String color,
    String? icon,
  }) async {
    try {
      final categoryData = {
        'name': name,
        'color': color,
        'icon': icon ?? '',
        'userId': _currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(_categoriesCollection).add(categoryData);
      notifyListeners();
    } catch (e) {
      print('Error agregando categoría: $e');
      rethrow;
    }
  }

  // Obtener categorías del usuario
  Stream<List<Map<String, dynamic>>> getUserCategories() {
    return _firestore
        .collection(_categoriesCollection)
        .where('userId', isEqualTo: _currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'color': data['color'] ?? '',
          'icon': data['icon'] ?? '',
        };
      }).toList();
    });
  }

  // ===== FAMILIAS =====

  // Crear una nueva familia
  Future<family_model.Family?> createFamily(String familyName, String adminUid, {String? customPassword}) async {
    try {
      final familyCode = generateFamilyCode();
      final familyPassword = customPassword ?? generateFamilyPassword();
      final docRef = _firestore.collection(_familiesCollection).doc();
      final newFamily = family_model.Family(
        id: docRef.id,
        name: familyName,
        code: familyCode,
        password: familyPassword,
        createdBy: adminUid,
        members: [adminUid],
        roles: {adminUid: family_model.FamilyRole.admin.toString().split('.').last}, // Asignar rol de administrador
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(newFamily.toJson());

      // Actualizar el familyId del usuario administrador
      await _firestore.collection(_usersCollection).doc(adminUid).update({
        'familyId': newFamily.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return newFamily;
    } catch (e) {
      print('Error creando familia: $e');
      rethrow;
    }
  }

  // Unirse a una familia existente usando un código
  Future<family_model.Family?> joinFamily(String familyCode, String userUid) async {
    try {
      print('🔧 joinFamily iniciado - código: $familyCode, usuario: $userUid');
      
      final querySnapshot = await _firestore
          .collection(_familiesCollection)
          .where('code', isEqualTo: familyCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final familyDoc = querySnapshot.docs.first;
        final familyData = familyDoc.data();
        
        print('🔧 Datos de familia encontrada: $familyData');
        
        // Manejar members - puede ser lista o mapa
        dynamic membersData = familyData['members'];
        List<String> members;
        
        if (membersData is List) {
          members = List<String>.from(membersData);
        } else if (membersData is Map) {
          members = membersData.keys.cast<String>().toList();
        } else {
          members = [];
        }
        
        // Manejar roles - puede ser lista o mapa
        dynamic rolesData = familyData['roles'];
        Map<String, String> roles;
        
        if (rolesData is List) {
          roles = <String, String>{};
          for (int i = 0; i < rolesData.length; i++) {
            if (rolesData[i] is String) {
              roles[rolesData[i]] = 'member';
            }
          }
        } else if (rolesData is Map) {
          roles = Map<String, String>.from(rolesData);
        } else {
          roles = <String, String>{};
        }
        
        print('🔧 Members actuales: $members');
        print('🔧 Roles actuales: $roles');
        
        if (!members.contains(userUid)) {
          // Añadir al usuario como miembro
          members.add(userUid);
          roles[userUid] = family_model.FamilyRole.member.toString().split('.').last;
          
          print('🔧 Members después de agregar: $members');
          print('🔧 Roles después de agregar: $roles');

          await familyDoc.reference.update({
            'members': members,
            'roles': roles,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Actualizar el familyId del usuario
          await _firestore.collection(_usersCollection).doc(userUid).update({
            'familyId': familyDoc.id,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          notifyListeners();
          
          // Crear objeto Family actualizado
          final updatedFamily = family_model.Family(
            id: familyDoc.id,
            name: familyData['name'] ?? '',
            code: familyData['code'] ?? '',
            password: familyData['password'] ?? '', // Agregar campo password
            createdBy: familyData['createdBy'] ?? '',
            members: members,
            roles: roles,
            createdAt: _parseDateTime(familyData['createdAt']),
            updatedAt: DateTime.now(),
          );
          
          print('✅ Usuario agregado a la familia exitosamente');
          return updatedFamily;
        } else {
          print('El usuario ya es miembro de esta familia.');
          
          // Crear objeto Family con datos actuales
          final currentFamily = family_model.Family(
            id: familyDoc.id,
            name: familyData['name'] ?? '',
            code: familyData['code'] ?? '',
            password: familyData['password'] ?? '', // Agregar campo password
            createdBy: familyData['createdBy'] ?? '',
            members: members,
            roles: roles,
            createdAt: _parseDateTime(familyData['createdAt']),
            updatedAt: _parseDateTime(familyData['updatedAt']),
          );
          
          return currentFamily;
        }
      }
      print('No se encontró ninguna familia con el código: $familyCode');
      return null;
    } catch (e) {
      print('❌ Error uniéndose a la familia: $e');
      rethrow;
    }
  }

  // Obtener información de la familia por ID
  Stream<family_model.Family?> getFamilyById(String familyId) {
    return _firestore.collection(_familiesCollection).doc(familyId).snapshots().map((doc) {
      if (doc.exists) {
        return family_model.Family.fromJson(doc.data()!);
      }
      return null;
    });
  }

  // Obtener contraseña de la familia (solo para administradores)
  Future<String?> getFamilyPassword(String familyId, String userId) async {
    try {
      final familyDoc = await _firestore.collection(_familiesCollection).doc(familyId).get();
      if (!familyDoc.exists) {
        print('❌ Familia no encontrada: $familyId');
        return null;
      }

      final familyData = familyDoc.data()!;
      
      // Verificar que el usuario es administrador de la familia
      final roles = familyData['roles'] as Map<String, dynamic>? ?? {};
      final userRole = roles[userId] as String?;
      
      if (userRole != 'admin') {
        print('❌ Usuario $userId no es administrador de la familia $familyId');
        return null;
      }

      // Retornar la contraseña solo si es administrador
      final password = familyData['password'] as String?;
      if (password != null) {
        print('✅ Contraseña obtenida para administrador $userId');
        return password;
      } else {
        print('⚠️ Familia no tiene contraseña configurada');
        return null;
      }
    } catch (e) {
      print('❌ Error obteniendo contraseña de familia: $e');
      return null;
    }
  }

  // Obtener miembros de la familia
  Future<List<Map<String, dynamic>>> getFamilyMembers(String familyId) async {
    try {
      final familyDoc = await _firestore.collection(_familiesCollection).doc(familyId).get();
      if (familyDoc.exists) {
        final familyData = familyDoc.data()!;
        
        // Manejar members - puede ser lista o mapa
        dynamic membersData = familyData['members'];
        List<String> memberUids;
        
        if (membersData is List) {
          memberUids = List<String>.from(membersData);
        } else if (membersData is Map) {
          memberUids = membersData.keys.cast<String>().toList();
        } else {
          memberUids = [];
        }
        
        // Manejar roles - puede ser lista o mapa
        dynamic rolesData = familyData['roles'];
        Map<String, String> memberRoles;
        
        if (rolesData is List) {
          memberRoles = <String, String>{};
          for (int i = 0; i < rolesData.length; i++) {
            if (rolesData[i] is String) {
              memberRoles[rolesData[i]] = 'member';
            }
          }
        } else if (rolesData is Map) {
          memberRoles = Map<String, String>.from(rolesData);
        } else {
          memberRoles = <String, String>{};
        }

        if (memberUids.isEmpty) {
          return [];
        }

        final usersSnapshot = await _firestore
            .collection(_usersCollection)
            .where(FieldPath.documentId, whereIn: memberUids)
            .get();

        return usersSnapshot.docs.map((userDoc) {
          final userData = userDoc.data();
          return {
            'uid': userDoc.id,
            'displayName': userData['displayName'] ?? userData['email'],
            'role': memberRoles[userDoc.id] ?? family_model.FamilyRole.member.toString().split('.').last,
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error obteniendo miembros de la familia: $e');
      rethrow;
    }
  }

  // Actualizar el rol de un miembro de la familia
  Future<void> updateFamilyMemberRole(String familyId, String memberUid, family_model.FamilyRole role) async {
    try {
      final familyDocRef = _firestore.collection(_familiesCollection).doc(familyId);
      await familyDocRef.update({
        'roles.${memberUid}': role.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      print('Error actualizando rol de miembro: $e');
      rethrow;
    }
  }

  // ===== USUARIOS =====

  // Crear perfil de usuario
  // NOTA: Esta función ahora se llama desde AuthRepository. No la llamar directamente.
  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
    String? photoURL,
  }) async {
    try {
      final userData = {
        'uid': uid,
        'name': name,
        'email': email,
        'photoURL': photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(_usersCollection).doc(uid).set(userData, SetOptions(merge: true));
      notifyListeners();
    } catch (e) {
      print('Error creando perfil de usuario: $e');
      rethrow;
    }
  }

  // Obtener perfil del usuario
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'uid': doc.id,
          'name': data['displayName'] ?? data['name'] ?? '',
          'email': data['email'] ?? '',
          'photoURL': data['photoURL'] ?? '',
          'familyId': data['familyId'],
        };
      }
      return null;
    } catch (e) {
      print('Error obteniendo perfil de usuario: $e');
      return null;
    }
  }

  // Actualizar perfil del usuario
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? photoURL,
    String? familyId,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (photoURL != null) updateData['photoURL'] = photoURL;
      if (familyId != null) updateData['familyId'] = familyId;

      await _firestore.collection(_usersCollection).doc(uid).update(updateData);
      notifyListeners();
    } catch (e) {
      print('Error actualizando perfil de usuario: $e');
      rethrow;
    }
  }

  // ===== UTILIDADES =====

  // Generar código de familia (ahora en la clase, no privado)
  String generateFamilyCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(6, (index) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  // Generar contraseña de familia
  String generateFamilyPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(8, (index) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  // Obtener estadísticas del mes
  Future<Map<String, dynamic>> getMonthStatistics(DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final snapshot = await _firestore
          .collection(_eventsCollection)
          .where('date', isGreaterThanOrEqualTo: _dateTimeToTimestamp(startOfMonth))
          .where('date', isLessThanOrEqualTo: _dateTimeToTimestamp(endOfMonth))
          .where('familyId', isEqualTo: _currentUserId)
          .get();

      final events = snapshot.docs.map((doc) => doc.data()).toList();
      
      // Calcular estadísticas
      final stats = <String, int>{};
      for (final event in events) {
        final category = event['category'] ?? 'Sin categoría';
        stats[category] = (stats[category] ?? 0) + 1;
      }

      return {
        'totalEvents': events.length,
        'categories': stats,
        'daysWithEvents': events.map((e) => _timestampToDateTime(e['date']).day).toSet().length,
      };
    } catch (e) {
      print('Error obteniendo estadísticas del mes: $e');
      return {
        'totalEvents': 0,
        'categories': {},
        'daysWithEvents': 0,
      };
    }
  }

  // Método auxiliar para parsear fechas desde Firebase
  DateTime _parseDateTime(dynamic dateData) {
    if (dateData == null) {
      return DateTime.now();
    }
    
    if (dateData is Timestamp) {
      return dateData.toDate();
    }
    
    if (dateData is String) {
      try {
        return DateTime.parse(dateData);
      } catch (e) {
        print('❌ Error parseando fecha string: $e');
        return DateTime.now();
      }
    }
    
    if (dateData is DateTime) {
      return dateData;
    }
    
    print('❌ Tipo de fecha no reconocido: ${dateData.runtimeType}');
    return DateTime.now();
  }

  // Remover usuario de una familia
  Future<void> removeUserFromFamily(String familyId, String userId) async {
    try {
      print('🔧 Removiendo usuario $userId de familia $familyId');
      
      // Obtener la familia actual
      final familyDoc = await _firestore.collection('families').doc(familyId).get();
      if (!familyDoc.exists) {
        throw Exception('Familia no encontrada');
      }
      
      final familyData = familyDoc.data()!;
      
      // Manejar members - puede ser lista o mapa
      dynamic membersData = familyData['members'];
      Map<String, dynamic> members;
      
      if (membersData is List) {
        // Convertir lista a mapa
        members = <String, dynamic>{};
        for (int i = 0; i < membersData.length; i++) {
          if (membersData[i] is String) {
            members[membersData[i]] = true;
          }
        }
      } else if (membersData is Map) {
        members = Map<String, dynamic>.from(membersData);
      } else {
        members = <String, dynamic>{};
      }
      
      // Manejar roles - puede ser lista o mapa
      dynamic rolesData = familyData['roles'];
      Map<String, dynamic> roles;
      
      if (rolesData is List) {
        // Convertir lista a mapa
        roles = <String, dynamic>{};
        for (int i = 0; i < rolesData.length; i++) {
          if (rolesData[i] is String) {
            roles[rolesData[i]] = 'member';
          }
        }
      } else if (rolesData is Map) {
        roles = Map<String, dynamic>.from(rolesData);
      } else {
        roles = <String, dynamic>{};
      }
      
      print('🔧 Members antes: $members');
      print('🔧 Roles antes: $roles');
      
      // Remover al usuario de la lista de miembros
      members.remove(userId);
      roles.remove(userId);
      
      print('🔧 Members después: $members');
      print('🔧 Roles después: $roles');
      
      // Actualizar la familia
      await _firestore.collection('families').doc(familyId).update({
        'members': members,
        'roles': roles,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Actualizar el usuario (quitar familyId)
      await _firestore.collection('users').doc(userId).update({
        'familyId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Usuario removido de la familia exitosamente');
      
    } catch (e) {
      print('❌ Error removiendo usuario de familia: $e');
      rethrow;
    }
  }

  // ===== PLANTILLAS DE TURNOS =====

  // Agregar plantilla de turno
  Future<void> addShiftTemplate({
    required String name,
    required String colorHex,
    required String startTime,
    required String endTime,
    String? description,
    String? familyId,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final shiftData = {
        'name': name,
        'colorHex': colorHex,
        'textColorHex': '#FFFFFF', // Color de texto por defecto
        'textSize': 16.0, // Tamaño de texto por defecto
        'startTime': startTime,
        'endTime': endTime,
        'description': description ?? '',
        'familyId': familyId ?? _currentUserId,
        'userId': userId,
        'createdAt': _dateTimeToTimestamp(DateTime.now()),
        'updatedAt': _dateTimeToTimestamp(DateTime.now()),
      };

      await _firestore
          .collection(_shiftTemplatesCollection)
          .add(shiftData);

      print('✅ Plantilla de turno agregada exitosamente');
    } catch (e) {
      print('❌ Error agregando plantilla de turno: $e');
      rethrow;
    }
  }

  // Obtener plantillas de turnos de la familia
  Stream<List<Map<String, dynamic>>> getShiftTemplatesStream({String? familyId}) {
    try {
      final query = _firestore
          .collection(_shiftTemplatesCollection)
          .where('familyId', isEqualTo: familyId ?? _currentUserId);

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      print('❌ Error obteniendo plantillas de turnos: $e');
      rethrow;
    }
  }

  // Obtener plantillas de turnos (una sola vez)
  Future<List<Map<String, dynamic>>> getShiftTemplates({String? familyId}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_shiftTemplatesCollection)
          .where('familyId', isEqualTo: familyId ?? _currentUserId)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo plantillas de turnos: $e');
      rethrow;
    }
  }

  // Actualizar plantilla de turno
  Future<void> updateShiftTemplate({
    required String id,
    required String name,
    required String colorHex,
    required String textColorHex,
    required double textSize,
    required String startTime,
    required String endTime,
    String? description,
  }) async {
    try {
      await _firestore
          .collection(_shiftTemplatesCollection)
          .doc(id)
          .update({
        'name': name,
        'colorHex': colorHex,
        'textColorHex': textColorHex,
        'textSize': textSize,
        'startTime': startTime,
        'endTime': endTime,
        'description': description ?? '',
        'updatedAt': _dateTimeToTimestamp(DateTime.now()),
      });

      print('✅ Plantilla de turno actualizada exitosamente');
    } catch (e) {
      print('❌ Error actualizando plantilla de turno: $e');
      rethrow;
    }
  }

  // Eliminar plantilla de turno
  Future<void> deleteShiftTemplate(String id) async {
    try {
      await _firestore
          .collection(_shiftTemplatesCollection)
          .doc(id)
          .delete();

      print('✅ Plantilla de turno eliminada exitosamente');
    } catch (e) {
      print('❌ Error eliminando plantilla de turno: $e');
      rethrow;
    }
  }

  // Obtener plantilla de turno por ID
  Future<Map<String, dynamic>?> getShiftTemplateById(String id) async {
    try {
      final docSnapshot = await _firestore
          .collection(_shiftTemplatesCollection)
          .doc(id)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        data['id'] = docSnapshot.id;
        return data;
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo plantilla de turno: $e');
      rethrow;
    }
  }
}

// Proveedor de Riverpod para FirestoreService
final firestoreServiceProvider = ChangeNotifierProvider((ref) => FirestoreService());
